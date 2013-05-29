# Replaces old SSIS Package "Test_Scoring_Nightly_Update"

#--------OLD WAY------------#
#counts rows in Users table
#Output is array with padded output
#Looks for a 0 entry with leading space to reflect empty table
#$UsersTBL = sqlcmd -d Test -Q "Select count(*) From Users2"
#$isEmpty = $UsersTBL[2].endswith(" 0")

#Builds Flat LDAP Style output that is expected.
#Creates tab-separated file of all AD users. Several fields are not used in database (Will remove later but need correct # of spaces now)
#Removes quotation marks from output, removes header information, and saves in ANSI format.

#################################################################################
#------TEMPORARY COMMENT - Need ability to run AD module on SQL server----------#
#################################################################################
#Import-Module ActiveDirectory
#$sampleOutput = Get-ADUser -Filter {samaccountname -like "bj*"} -SearchBase "DC=ad,DC=wiu,DC=edu" -Properties Title, Department, mail, HomePhone, telephoneNumber, Office, physicalDeliveryOfficeName, Division, EmployeeID, Fax, HomePage, MobilePhone, Organization, OtherName, l, POBox, PostalCode, Modified, PasswordExpired, PasswordLastSet, st, samaccountname, State, StreetAddress, City, Country, PasswordNeverExpires | Select-Object -Property Name, objectClass, GivenName, Surname, Title, Department, mail, HomePhone, telephoneNumber, Office, physicalDeliveryOfficeName, Division, EmployeeID, Fax, HomePage, MobilePhone, Organization, OtherName, l, POBox, PostalCode, Modified, PasswordExpired, PasswordLastSet, st, samaccountname, State, StreetAddress, City, Country, PasswordNeverExpires | ConvertTo-Csv -Delimiter "`t" -NoTypeInformation
#$fixedOutput = $sampleOutput | Foreach {$_.replace("`"","")}
#$fixedOutput[1..$fixedOutput.Count] | Out-File -Encoding Default '\\ad.wiu.edu\wiu\Admin Data\heatupdate\heatuser.txt'

#Confirms that new heatuser.txt file has been exported
$isFileThere = Test-Path "\\ad.wiu.edu\wiu\Admin Data\heatupdate\heatuser.txt"

if(!$isFileThere){
	Send-MailMessage -From "Brandon <bj-colley@wiu.edu>" -To "Brandon <bj-colley@wiu.edu>" -subject "Test score feed has encountered an error" -smtpserver smtp.wiu.edu
	Exit
}
#Confirms that new heatuser.txt file contains entries
elseif((Get-ChildItem "\\ad.wiu.edu\wiu\Admin Data\heatupdate\heatuser.txt").length -eq 0){
	Send-MailMessage -From "Brandon <bj-colley@wiu.edu>" -To "Brandon <bj-colley@wiu.edu>" -subject "Test score feed has encountered an error" -smtpserver smtp.wiu.edu
	Exit
}
#File looks fine. Perform update to tables
else{
	#Clear Users_BAK and Copy rows from Users into Users_BAK
	Invoke-Command {sqlcmd -d Test -Q "TRUNCATE TABLE USERS2_BAK"}
	Invoke-Command {sqlcmd -d Test -Q "INSERT INTO USERS2_BAK SELECT * FROM USERS2"}
	#Clear Users table 
	Invoke-Command {sqlcmd -d Test -Q "TRUNCATE TABLE USERS2"}
	#Fill Users table with contents from heatuser.txt by calling SSIS package
	Invoke-Command {dtexec.exe /File "d:\SSIS Development\Test_Scoring_Users.dtsx"}
}

#Rename previous heatuser file
$todaysFile = "heatuser"+(Get-Date -UFormat "%Y%m%d")+".txt"
ren "\\ad.wiu.edu\wiu\Admin Data\heatupdate\heatuser.txt" "\\ad.wiu.edu\wiu\Admin Data\heatupdate\$todaysFile"