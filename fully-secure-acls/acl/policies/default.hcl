
### Works for the API and DNS?!
service_prefix "" {
  policy = "read"
}


## Required to be "read" for UI and DNS
## API doesn't matter
node_prefix "" {
  policy = "read"
} 
