The code given in the connected folders contains the version control of both platform's Infrastructure as code solution.
due to various constraints spoken about in the report, solutions are lower in complexity than planned.
an alternative was also discussed.

This code was developed straight into the cloud shell editors of both azure and google. any other config has not been tested.

The complexity of the program is partially lacking due to constraints discussed in the dissertation file in this repo

For Azure:
-click cloud shell icon to the right of search bar.
-click the "{ }" icon at the top of cloud shell CLI panel
-in CLI type "touch" followed by file names in folder.
-paste code into files (not sure how to upload)
-type in this order:
terraform init -upgrade, terraform plan -out azMain.tfplan, terraform apply azMain.tfplan. terraform plan -destroy -out azMain.tfplan. terraform apply azMain.tfplan

for GCP:
-click "activate cloud shell"
-open editor
-same as above.
terraform init -upgrade, terraform plan -out gcpMain.tfplan, terraform apply gcpMain.tfplan. terraform plan -destroy -out gcpMain.tfplan. terraform apply gcpMain.tfplan.

