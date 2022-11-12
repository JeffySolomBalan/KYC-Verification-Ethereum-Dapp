# Creation & Verification of KYC over Ethereum Blockchain
An Ethereum Dapp for KYC Creation & Verification Process



## Steps to follow

	1.	Once the Contract is deployed, multiple banks can be created using addBank method. Note this method can be accessed only by Admin Account.


	2.	Once the sufficient number of bank accounts are created, multiple Customer accounts can be created using addCustomer method. 
		Note this method will create only customer account with kycStatus set to false, and bank as 0x000.
	
	
	3.	In order to do KYC for the created customer, addRequest method needs to called, this will add the customer to the KYCRequest list.
	
	
	4.	To Verify KYC for a particular customer, verifyKYC method needs to called, this method would make the status of the KYC to true for the specified customer. 
	
	
	5.	Then Other banks can upVote/downVote the customer account for which KYC is done.
	
	
	6.	Whenver an upvote or downvote is marked by any bank, code will check whether Upvote is greater than downvote if it is not then directly set the kycStatus of the customer as invalid. 
		If Upvote is greater than downvote then check the number of downvote is greater than one-third of the no. of banks. 
		If downvote is lesser, then again set the KYCStatus as invalid.
		
		
	7.	When modifyCustomer method is called KYCStatus of the particular would be resetted and it would be removed from KYCRequest list too.
	
	
	8.	One bank can report other banks using reportBank Method. Whenever a bank gets reported for suspicious activity, no. of complaints registered against the bank is checked.
		If it is greater than one third of the no. of banks then that bank is stopped from Voting/Carring any more KYC Process.
	
	
	9.	We have other method like modifyIsAllowed to Vote & removeBank which can be accessed only by admin.
	
	
	10.	There are other method to view details like Customer, Bank, Request Details
