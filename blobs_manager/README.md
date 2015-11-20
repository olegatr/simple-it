#Blobs Manager


###Requirements

- Ruby 1.9.3
- Gems:
 ```gem install azure```

###Usage: blob_copier [options]

    -a, --account-name name          account name
    -k, --storage-key key            storage key
    -s, --source source              source container name
    -d, --destination dest           destination container name
    -m, --maximum-blobs num          maximum blobs to copy
    -c, --clean-mode                 delete duplicate from source container

    
###Using Examples:
- Copy 20 blobs from cont1 to cont2:
>  ruby blob_copier.rb -a myname -k YSl8fQfRqmImu.... -s cont1 -d cont2 -m 20
  
- Copy all blobs from cont1 to cont2:
>  ruby blob_copier.rb -a myname -k YSl8fQfRqmImu.... -s cont1 -d cont2
   
- Delete blobs from source if exists and available in destination:
> ruby blob_copier.rb -a myname -k YSl8fQfRqmImu.... -s cont1 -d cont2 -c
