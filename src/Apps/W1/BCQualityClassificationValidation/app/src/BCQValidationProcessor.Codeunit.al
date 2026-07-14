codeunit 50101 "BCQ Validation Processor"
{
    procedure GreetCustomer(var ValidationCustomer: Record "BCQ Validation Customer")
    var
        WelcomeMsg: Label 'Welcome, %1', Comment = '%1 = customer full name';
    begin
        Message(WelcomeMsg, ValidationCustomer."Full Name");
    end;
}
