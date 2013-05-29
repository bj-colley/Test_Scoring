# Replaces old SSIS Package "Test_Scoring_Nightly_Update"
# If heatusers.txt file continiously fails to be built, it can be manually ran from:
# C:\scripts\buildHeatuserFile.ps1 --> This must be copied & run from your local workstation or DC.

#Confirms import file is available and not empty
#Then copies old data to Users_BAK table, builds new table, renames import file based on date

#variables:
$importFilePath = "\\ad.wiu.edu\wiu\Admin Data\heatupdate\heatuser.txt"
$emailRecipients = "Brandon <bj-colley@wiu.edu>", "Clinton <cw-pedigo@wiu.edu>"
$database = "Test_Scoring"
$table = "Users"
$table_BAK = "Users_BAK"

#Confirms that new heatuser.txt file has been exported
$isFileThere = Test-Path $importFilePath

if(!$isFileThere){
	Send-MailMessage -From "Brandon <bj-colley@wiu.edu>" -To $emailRecipients -subject "Test score feed has encountered an error" -Body "C:\scripts\updateTest_ScoringDB.ps1 failed on WIU-W2K3-SQL02. File: $importFilePath is unavailable or empty." -smtpserver smtp.wiu.edu
	Exit
}
#Confirms that new heatuser.txt file contains entries
elseif((Get-ChildItem $importFilePath).length -eq 0){
	Send-MailMessage -From "Brandon <bj-colley@wiu.edu>" -To $emailRecipients -subject "Test score feed has encountered an error" -Body "C:\scripts\updateTest_ScoringDB.ps1 failed on WIU-W2K3-SQL02. File: $importFilePath is unavailable or empty." -smtpserver smtp.wiu.edu
	Exit
}
#File looks fine. Perform update to tables
else{
	#Clear Users_BAK and Copy rows from Users into Users_BAK
	sqlcmd -d $database -Q "TRUNCATE TABLE $table_BAK"
	sqlcmd -d $database -Q "INSERT INTO $table_BAK SELECT * FROM $table"
	#Clear Users table 
	sqlcmd -d $database -Q "TRUNCATE TABLE $table"
	#Fill Users table with contents from heatuser.txt by calling SSIS package
	dtexec.exe /File "d:\SSIS Development\Test_Scoring_Users.dtsx"
}

#Rename previous heatuser file
$todaysFile = "heatuser"+(Get-Date -UFormat "%Y%m%d")+".txt"
ren $importFilePath "\\ad.wiu.edu\wiu\Admin Data\heatupdate\$todaysFile"