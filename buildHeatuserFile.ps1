# Creates File for Test_Scoring DB. 
# C:\Scripts\updateTest_ScoringDB.ps1 running on WIU-W2K3-SQL02 relies on this file to be built.
# !!!!--This script is a backup for Fred's script that runs nightly from the LDAP server --!!!!

#Builds Flat LDAP Style output that is expected.
#Creates tab-separated file of all AD users. Several fields are not used in database.
#Removes quotation marks from output, removes header information, and saves in ANSI format.

###############################################################################################
#------RUN THIS FROM DC OR WORKSTATION WITH TOOLS - Need ability to Import AD Module----------#
###############################################################################################
Import-Module ActiveDirectory
$sampleOutput = Get-ADUser -Filter {*} -SearchBase "DC=ad,DC=wiu,DC=edu" -Properties Title, Department, mail, HomePhone, telephoneNumber, Office, physicalDeliveryOfficeName, Division, EmployeeID, Fax, HomePage, MobilePhone, Organization, OtherName, l, POBox, PostalCode, Modified, PasswordExpired, PasswordLastSet, st, samaccountname, State, StreetAddress, City, Country, PasswordNeverExpires | Select-Object -Property Name, objectClass, GivenName, Surname, Title, Department, mail, HomePhone, telephoneNumber, Office, physicalDeliveryOfficeName, Division, EmployeeID, Fax, HomePage, MobilePhone, Organization, OtherName, l, POBox, PostalCode, Modified, PasswordExpired, PasswordLastSet, st, samaccountname, State, StreetAddress, City, Country, PasswordNeverExpires | ConvertTo-Csv -Delimiter "`t" -NoTypeInformation
$fixedOutput = $sampleOutput | Foreach {$_.replace("`"","")}
$fixedOutput[1..$fixedOutput.Count] | Out-File -Encoding Default '\\ad.wiu.edu\wiu\Admin Data\heatupdate\heatuser.txt'