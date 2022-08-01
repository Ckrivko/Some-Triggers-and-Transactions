--14. Create Table Logs
CREATE TABLE Logs (LogId INT primary key Identity
, AccountId INT
, OldSum MONEY
, NewSum MONEY)

GO
CREATE TRIGGER  tr_accountChange
ON Accounts for update
AS
	INSERT INTO Logs
	SELECT i.Id, d.Balance, i.Balance
	FROM inserted as i
	join deleted as d ON i.Id= d.Id
	where i.Balance <> d.Balance
go

--15. Create Table Emails
CREATE TABLE NotificationEmails(Id INT PRIMARY KEY IDENTITY
, Recipient INT
, [Subject] NVARCHAR(70)
, Body NVARCHAR(70) )
GO

CREATE or Alter TRIGGER tr_CreateNewNotificationEmail
ON Logs for Insert
as 
begin
		INSERT INTO NotificationEmails
    VALUES (
      (SELECT AccountId
       FROM inserted),
      (CONCAT('Balance change for account: ', (SELECT AccountId
                                               FROM inserted))),
      (CONCAT('On ', (SELECT GETDATE()
                      FROM inserted), 'your balance was changed from ', 
					  (SELECT OldSum
                        FROM inserted), 'to ', (SELECT NewSum
                        FROM inserted), '.'))
    )
end
go

--16. Deposit Money
CREATE PROC  usp_DepositMoney (@AccountId int, @MoneyAmount decimal(18,4))
AS
BEGIN
	IF(@MoneyAmount>0)
	BEGIN
		UPDATE Accounts
        SET Balance += @MoneyAmount				
	where Id= @AccountId
	END
		
END
GO

--17. Withdraw Money Procedure
CREATE or alter PROC usp_WithdrawMoney (@AccountId int, @MoneyAmount decimal(18,4))
AS 
BEGIN
	DECLARE @sum decimal(18,4)= (Select SUM(Balance- @MoneyAmount)
	from Accounts
	where Id=@AccountId)	
	
	IF(@MoneyAmount>0 and @sum>=0) 
		BEGIN
			UPDATE Accounts
			SET Balance -= @MoneyAmount				
		where Id= @AccountId
		END

END
GO

--18. Money Transfer
CREATE PROC usp_TransferMoney(@SenderId INT,
@ReceiverId INT , @Amount DECIMAL (18,4)) 
AS
BEGIN
exec usp_WithdrawMoney
@SenderId,@Amount
exec usp_DepositMoney
@ReceiverId, @Amount
END

GO

--20. *Massive Shopping

--I take the solution from
-- aguzelov/Aleksandur Gyuzelov

DECLARE @gameName NVARCHAR(50) = 'Safflower'
DECLARE @username NVARCHAR(50) = 'Stamat'

DECLARE @userGameId INT = (
  SELECT ug.Id
  FROM UsersGames AS ug
    JOIN Users AS u
      ON ug.UserId = u.Id
    JOIN Games AS g
      ON ug.GameId = g.Id
  WHERE u.Username = @username AND g.Name = @gameName)

DECLARE @userGameLevel INT = (SELECT Level
                              FROM UsersGames
                              WHERE Id = @userGameId)
DECLARE @itemsCost MONEY, @availableCash MONEY, @minLevel INT, @maxLevel INT

SET @minLevel = 11
SET @maxLevel = 12
SET @availableCash = (SELECT Cash
                      FROM UsersGames
                      WHERE Id = @userGameId)
SET @itemsCost = (SELECT SUM(Price)
                  FROM Items
                  WHERE MinLevel BETWEEN @minLevel AND @maxLevel)

IF (@availableCash >= @itemsCost AND @userGameLevel >= @maxLevel)

  BEGIN
    BEGIN TRANSACTION
    UPDATE UsersGames
    SET Cash -= @itemsCost
    WHERE Id = @userGameId
    IF (@@ROWCOUNT <> 1)
      BEGIN
        ROLLBACK
        RAISERROR ('Could not make payment', 16, 1)
      END
    ELSE
      BEGIN
        INSERT INTO UserGameItems (ItemId, UserGameId)
          (SELECT
             Id,
             @userGameId
           FROM Items
           WHERE MinLevel BETWEEN @minLevel AND @maxLevel)

        IF ((SELECT COUNT(*)
             FROM Items
             WHERE MinLevel BETWEEN @minLevel AND @maxLevel) <> @@ROWCOUNT)
          BEGIN
            ROLLBACK;
            RAISERROR ('Could not buy items', 16, 1)
          END
        ELSE COMMIT;
      END
  END

SET @minLevel = 19
SET @maxLevel = 21
SET @availableCash = (SELECT Cash
                      FROM UsersGames
                      WHERE Id = @userGameId)
SET @itemsCost = (SELECT SUM(Price)
                  FROM Items
                  WHERE MinLevel BETWEEN @minLevel AND @maxLevel)

IF (@availableCash >= @itemsCost AND @userGameLevel >= @maxLevel)

  BEGIN
    BEGIN TRANSACTION
    UPDATE UsersGames
    SET Cash -= @itemsCost
    WHERE Id = @userGameId

    IF (@@ROWCOUNT <> 1)
      BEGIN
        ROLLBACK
        RAISERROR ('Could not make payment', 16, 1)
      END
    ELSE
      BEGIN
        INSERT INTO UserGameItems (ItemId, UserGameId)
          (SELECT
             Id,
             @userGameId
           FROM Items
           WHERE MinLevel BETWEEN @minLevel AND @maxLevel)

        IF ((SELECT COUNT(*)
             FROM Items
             WHERE MinLevel BETWEEN @minLevel AND @maxLevel) <> @@ROWCOUNT)
          BEGIN
            ROLLBACK
            RAISERROR ('Could not buy items', 16, 1)
          END
        ELSE COMMIT;
      END
  END

SELECT i.Name AS [Item Name]
FROM UserGameItems AS ugi
  JOIN Items AS i
    ON i.Id = ugi.ItemId
  JOIN UsersGames AS ug
    ON ug.Id = ugi.UserGameId
  JOIN Games AS g
    ON g.Id = ug.GameId
WHERE g.Name = @gameName
ORDER BY [Item Name]

go

--21. Employees with Three Projects
CREATE OR ALTER PROC usp_AssignProject(@emloyeeId INT, @projectID INT)
AS
BEGIN 
	BEGIN TRAN
		INSERT INTO EmployeesProjects 
			VALUES(@emloyeeId, @projectID)
				DECLARE @count int =(select count(*)from EmployeesProjects as ep
									where ep.EmployeeID=@emloyeeId) 
				if(@count>3)
					BEGIN
						RAISERROR('The employee has too many projects!',16,1)
						ROLLBACK
						RETURN
					END
 
	COMMIT
END
   GO    
EXEC usp_AssignProject 1,1
GO


							





