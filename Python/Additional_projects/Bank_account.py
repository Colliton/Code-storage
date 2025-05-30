"""
BankAccount and MinimumBalanceAccount classes with transaction result handling.

Requirements:
- Users can create bank accounts with an initial balance.
- Users can deposit money into their account.
- Users can attempt to withdraw money from their account.
- Withdrawals return a Result object indicating success or failure, with a message and withdrawn amount.
- MinimumBalanceAccount enforces a minimum balance requirement, preventing withdrawals that would lower the balance below this minimum.
- Deposits and withdrawals must be positive amounts.

Input:
- deposit(amount: float) - adds the specified amount to the account balance.
- try_withdraw(amount: float) - attempts to withdraw the specified amount from the account.
  Returns a Result instance indicating success (Ok) or failure (Error).

Output:
- Result object with:
    - isSuccess (bool): True for success, False for failure.
    - message (str): Description of the transaction result.
    - value (float|None): The amount involved in the transaction.

Example usage:
    account = BankAccount(500)
    print(account)  # Account #1: Balance = 500
    result = account.try_withdraw(100)
    if result.is_ok():
        print(result.message)
    else:
        print(result.message)

    min_acc = MinimumBalanceAccount(1500, minimumBalance=1000)
    withdraw_result = min_acc.try_withdraw(600)
    print(withdraw_result.message)  # Should prevent withdrawal if it breaks minimum balance

"""

class Result:
    "You can print the result of transaction"

    def __init__(self, message, value=None):
        self.isSuccess = None
        self.message = message
        self.value = value

    def is_ok(self):
        return self.isSuccess


class Ok(Result):
    def __init__(self, message, value=None):
        super().__init__(message, value)
        self.isSuccess = True


class Error(Result):
    def __init__(self, message, value=None):
        super().__init__(message, value)
        self.isSuccess = False


class BankAccount:
    "You can deposit and withdraw your money. You can also see through your account balance."
    id = 1

    def __init__(self, balance=0):
        self.balance = balance
        self.id = BankAccount.id
        BankAccount.id += 1

    def deposit(self, amount):
        if amount <= 0:
            return Error("Deposit amount must be positive", amount)
        self.balance += amount
        return Ok("Deposit successful", amount)

    def try_withdraw(self, amount):
        if amount <= 0:
            return Error("Withdrawal amount must be positive", amount)
        if self.balance >= amount:
            self.balance -= amount
            return Ok("The money has been withdrawn", amount)
        return Error("You don't have enough money on your account", amount)

    def __str__(self):
        return f"Account #{self.id}: Balance = {self.balance}"


class MinimumBalanceAccount(BankAccount):
    def __init__(self, balance=0, minimumBalance=1000):
        super().__init__(balance)
        self.minimumBalance = minimumBalance

    def try_withdraw(self, amount):
        if amount <= 0:
            return Error("Withdrawal amount must be positive", amount)
        if (self.balance - amount) >= self.minimumBalance:
            return super().try_withdraw(amount)
        return Error(
            f"You must maintain a minimum balance of {self.minimumBalance}",
            amount,
        )
