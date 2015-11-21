require 'azure'
require_relative 'log'
require 'optparse'
require 'ostruct'

def copy_blob(azure_blob_service, blob, dest_blob, new_name)
  if !dest_blob
    copy_id, copy_status = azure_blob_service.copy_blob($options.destination, new_name, $options.source, blob.name)
    Log.info "COPY FROM #{$options.source} - #{blob.name} TO #{$options.destination} - #{new_name} COPY_ID #{copy_id} COPY_STATUS #{copy_status}"
    return true
  else
    Log.info "COPY SKIPPED FROM #{$options.source} - #{blob.name} TO #{$options.destination} - #{new_name} COPY_ID #{copy_id} COPY_STATUS #{copy_status}"
  end
  return false
end

def delete_blob(azure_blob_service, blob, dest_blob)
  if dest_blob and is_identical(blob, dest_blob)
    azure_blob_service.delete_blob($options.source, blob.name)
    Log.info "DELETE FROM #{$options.source} - #{blob.name}"
  end
end

def load_all_dest_blobs(blobs)
  blobs_list = []
  Log.info "Fetching blobs from #{$options.destination}"
  destination_container_blobs = blobs.list_blobs($options.destination, {:timeout => 340, :max_results => 1000})
  destination_container_blobs.each {|blob| blobs_list << blob}
  Log.info "+#{destination_container_blobs.length} from #{$options.destination} total : #{blobs_list.length}"
  while destination_container_blobs.continuation_token > ""
    destination_container_blobs = blobs.list_blobs($options.destination, {:marker => destination_container_blobs.continuation_token, :timeout => 340, :max_results => 1000})
    destination_container_blobs.each {|blob| blobs_list << blob}
    Log.info "+#{destination_container_blobs.length} from #{$options.destination} total : #{blobs_list.length}"
  end
    Log.info "#{blobs_list.length} fetched from #{$options.destination}"
  blobs_list
end

def run
  begin
    Azure.storage_account_name = $options.account_name
    Azure.storage_access_key   = $options.storage_key
    blobs = Azure.blobs
    azure_blob_service = Azure::Blob::BlobService.new

    destination_container_blobs = load_all_dest_blobs(blobs)
    files_copied_count = 0
    Log.info "Fetching blobs from #{$options.source}"
    source_blobs = blobs.list_blobs($options.source, {:timeout => 240, :max_results => 1000})
    Log.info "#{source_blobs.length} fetched from #{$options.source}"
    while source_blobs.continuation_token > ""
      source_blobs.each do |blob|
        new_name = to_new_name(blob.name)
        if new_name
          dest_blob = destination_container_blobs.find{|blob| blob.name == new_name}
          if $options.delete_mode
            delete_blob(azure_blob_service, blob, dest_blob)
          else
            files_copied_count += 1 if copy_blob(azure_blob_service, blob, dest_blob, new_name)
          end
        end
        break if $options.max_blobs and $options.max_blobs == files_copied_count
      end
      break if $options.max_blobs and $options.max_blobs == files_copied_count
      source_blobs = blobs.list_blobs($options.source, {:marker => source_blobs.continuation_token, :timeout => 240, :max_results => 1000})
      Log.info "#{source_blobs.length} fetched from #{$options.source}"
    end
  rescue Exception => exp
    Log.error "Error : #{exp.message}, trace: #{exp.backtrace}"
  end
end

def is_identical(blob_a, blob_b)
  return (blob_a.properties[:lease_status] == blob_b.properties[:lease_status] and
      blob_a.properties[:lease_state] == blob_b.properties[:lease_state] and
      blob_a.properties[:content_length] == blob_b.properties[:content_length] and
      blob_a.properties[:content_type] == blob_b.properties[:content_type] and
      blob_a.properties[:blob_type] == blob_b.properties[:blob_type])
end

def to_new_name(old_name)
  match = old_name.match /MBS-21dfaf5e-36e4-4394-a133-24c044f172c5\/CBB_P1-WMS\/9\.255\.2\.(15|11):(Media\/|Media.Contents\/)(.*):\//
  new_file = match && match.length == 4 ? match[3] : nil
  return nil if new_file.nil?
  if new_file.index('Contents') == 0
    return new_file[9..-1]
  end
  new_file
end


$options = OpenStruct.new
OptionParser.new do |opt|
  opt.on('-a', '--account-name name', 'account name') { |name| $options.account_name = name }
  opt.on('-k', '--storage-key key', 'storage key') { |key| $options.storage_key = key }
  opt.on('-s', '--source source', 'source container name') { |source| $options.source = source }
  opt.on('-d', '--destination dest', 'destination container name') { |dest| $options.destination = dest }
  opt.on('-m', '--maximum-blobs num', 'maximum blobs to copy') { |num| $options.max_blobs = num.to_i }
  opt.on('-c', '--clean-mode', 'delete duplicate from source container') { $options.delete_mode = true }
end.parse!

run
