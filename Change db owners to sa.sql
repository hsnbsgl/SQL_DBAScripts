/*
  Change db owners to sa account
  Execute the result set
*/
SELECT 'ALTER AUTHORIZATION ON DATABASE::' + name + ' to sa ;' FROM sys.databases WHERE owner_sid<>0x01
