# aws-cloudformation

Repository to help practice developing and deploying **cloudformation stacks** to AWS.  
There are different examples in the different folders.  

- iam    

There are some scripts in the `utils` directory to help create some pre-reqs, like an `s3` bucket needed to hold `json` policies in AWS, so the cloudformation that creates IAM resources can pull policy documents securely from **aws s3**.  

### IAM  
#### Pre-Requisite  
Need to create an `s3` bucket. and upload the `json` policies.  
There are scripts in the `utils` directory to help automate these tasks. 
- create bucket   
    ***This create a private `s3` bucket in a region `us-east-1`, with versioning enabled*** 
```sh
./utils/create-bucket.sh
```
- upload policies to bucket   
    ***This will upload all files in the `iam/policies` directory to a folder `iam-policies` within the bucket***   
```sh
./utils/upload-policies.sh
```
- delete bucket   
    ***This will empy bucket, if it's not empty and delete the bucket. Only run for clean-up.*** 
```sh
./utils/delete-bucket.sh
```

#### Create CloudFormation stack  
Once all pre-requisites are completed, proceed to deploying the cloudformation.  

##### Read-Only sample  
- Validate template  
```sh
aws cloudformation --region us-east-1 validate-template --template-body file://iam/user-role-ro1.yml
```

- create cloudformation stack  
```sh
aws cloudformation --region us-east-1 \
deploy --stack-name AppDevReadOnlyIAMStack \
--template-file iam/user-role-ro1.yml \
--capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND
```

- check if cloudformation stack exists  
```sh
aws cloudformation --region us-east-1 describe-stacks --stack-name AppDevReadOnlyIAMStack
```

- delete cloudformation stack  
```sh
aws cloudformation --region us-east-1 delete-stack --stack-name AppDevReadOnlyIAMStack
```
