namespace Microsoft.SubscriptionBilling;

using System.Security.User;
using Microsoft.CRM.Team;

table 8022 "Contract Billing Err Log"
{
    Caption = 'Contract Billing Error Log';
    DataClassification = CustomerContent;
    DrillDownPageId = "Contract Billing Err Log";
    LookupPageId = "Contract Billing Err Log";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            ToolTip = 'Specifies the unique entry number for the error log record.';
            AutoIncrement = true;
        }
        field(3; "Billing Template Code"; Code[20])
        {
            Caption = 'Billing Template Code';
            ToolTip = 'Specifies the billing template code that was being processed when the error occurred.';
            TableRelation = "Billing Template".Code;
        }
        field(4; "Error Text"; Text[250])
        {
            Caption = 'Error Text';
            ToolTip = 'Specifies the error message that occurred during the auto contract billing process.';
        }
        field(5; "Subscription"; Code[20])
        {
            Caption = 'Subscription';
            ToolTip = 'Specifies the subscription number that was being processed when the error occurred.';
            TableRelation = "Subscription Header"."No.";
        }
        field(6; "Subscription Entry No."; Integer)
        {
            Caption = 'Subscription Entry No.';
            ToolTip = 'Specifies the subscription line entry number that was being processed when the error occurred.';
            TableRelation = "Subscription Line"."Entry No.";
        }
        field(7; "Subscription Contract No."; Code[20])
        {
            Caption = 'Subscription Contract No.';
            ToolTip = 'Specifies the subscription contract number that was being processed when the error occurred.';
            TableRelation = "Customer Subscription Contract"."No.";
        }
        field(8; "Contract Line No."; Integer)
        {
            Caption = 'Contract Line No.';
            ToolTip = 'Specifies the contract line number that was being processed when the error occurred.';
            TableRelation = "Cust. Sub. Contract Line"."Line No." where("Subscription Contract No." = field("Subscription Contract No."));
        }
        field(9; "Contract Type"; Code[20])
        {
            Caption = 'Contract Type';
            ToolTip = 'Specifies the contract type that was being processed when the error occurred.';
            TableRelation = "Subscription Contract Type".Code;
        }
        field(10; "Assigned User ID"; Code[50])
        {
            Caption = 'Assigned User ID';
            ToolTip = 'Specifies the user ID assigned to handle this error.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "User Setup"."User ID";
        }
        field(11; "Salesperson Code"; Code[20])
        {
            Caption = 'Salesperson Code';
            ToolTip = 'Specifies the salesperson code associated with the contract that had an error.';
            TableRelation = "Salesperson/Purchaser";
        }
    }
    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
    local procedure InitRecord()
    begin
        Rec.Init();
        Rec."Entry No." := 0;
    end;

    internal procedure InsertUnspecificLog(ErrorText: Text[250])
    begin
        InitRecord();
        Rec."Error Text" := ErrorText;
        Rec.Insert();
    end;

    internal procedure InsertLogFromBillingTemplate(BillingTemplateCode: Code[20]; ErrorText: Text[250])
    begin
        InitRecord();
        Rec."Billing Template Code" := BillingTemplateCode;
        Rec."Error Text" := ErrorText;
        Rec.Insert();
    end;

    internal procedure InsertLogFromSubscriptionLine(BillingTemplateCode: Code[20]; SubscriptionLine: Record "Subscription Line"; ErrorText: Text[250])
    var
        CustomerSubscriptionContract: Record "Customer Subscription Contract";
    begin
        InitRecord();
        Rec."Billing Template Code" := BillingTemplateCode;
        Rec."Error Text" := ErrorText;
        Rec."Subscription" := SubscriptionLine."Subscription Header No.";
        Rec."Subscription Entry No." := SubscriptionLine."Entry No.";
        Rec."Subscription Contract No." := SubscriptionLine."Subscription Contract No.";
        Rec."Contract Line No." := SubscriptionLine."Subscription Contract Line No.";
        case SubscriptionLine.Partner of
            SubscriptionLine.Partner::Customer:
                if CustomerSubscriptionContract.Get(SubscriptionLine."Subscription Contract No.") then begin
                    Rec."Contract Type" := CustomerSubscriptionContract."Contract Type";
                    Rec."Assigned User ID" := CustomerSubscriptionContract."Assigned User ID";
                    Rec."Salesperson Code" := CustomerSubscriptionContract."Salesperson Code";
                end;
        end;
        Rec.Insert();
    end;
}
