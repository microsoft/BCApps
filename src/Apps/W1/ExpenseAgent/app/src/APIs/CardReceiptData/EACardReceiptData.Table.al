// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

/// <summary>
/// Staging record for receipt data that is applied to a corporate card expense and its expense report line.
/// Blank values mean "do not fill". The record and its lines are deleted when the data is applied.
/// </summary>
table 7427 "EA Card Receipt Data"
{
    Access = Internal;
    Caption = 'Card Receipt Data';
    DataClassification = CustomerContent;
    ReplicateData = false;

    fields
    {
        field(1; Id; Guid)
        {
            Caption = 'Id';
            ToolTip = 'Specifies the identifier of the receipt data.';
        }
        field(2; "Expense SystemId"; Guid)
        {
            Caption = 'Expense System Id';
            ToolTip = 'Specifies the corporate card expense that the receipt data is applied to.';
        }
        field(3; "Expense No."; Code[20])
        {
            Caption = 'Expense No.';
            ToolTip = 'Specifies the number of the corporate card expense that the receipt data is applied to.';
            Editable = false;
        }
        field(10; "File Name"; Text[250])
        {
            Caption = 'File Name';
            ToolTip = 'Specifies the file name of the receipt, including the extension.';
        }
        field(11; "Attachment Content"; Blob)
        {
            Caption = 'Attachment Content';
            ToolTip = 'Specifies the receipt file.';
        }
        field(20; "Expense Category"; Code[20])
        {
            Caption = 'Expense Category';
            ToolTip = 'Specifies the expense category to set when the expense or line has none.';
        }
        field(22; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description to set when the expense or line has none.';
        }
        field(23; Justification; Text[100])
        {
            Caption = 'Justification';
            ToolTip = 'Specifies the justification to set when the expense or line has none.';
        }
        field(25; "Merchant Registration No."; Text[50])
        {
            Caption = 'Merchant Registration No.';
            ToolTip = 'Specifies the merchant registration number to set when the expense or line has none.';
        }
        field(26; "Merchant VAT Registration No."; Text[20])
        {
            Caption = 'Merchant VAT Registration No.';
            ToolTip = 'Specifies the merchant VAT registration number to set when the expense or line has none.';
        }
        field(27; "Expense Ext. Doc. No."; Code[30])
        {
            Caption = 'Expense External Document No.';
            ToolTip = 'Specifies the receipt number to set when the expense or line has none.';
        }
    }

    keys
    {
        key(PK; Id)
        {
            Clustered = true;
        }
        key(Expense; "Expense SystemId")
        {
        }
    }

    trigger OnInsert()
    begin
        if IsNullGuid(Rec.Id) then
            Rec.Id := CreateGuid();
    end;

    trigger OnDelete()
    var
        CardReceiptParticipant: Record "EA Card Receipt Participant";
        CardReceiptItem: Record "EA Card Receipt Item";
        CardReceiptVATSpec: Record "EA Card Receipt VAT Spec.";
    begin
        CardReceiptParticipant.SetRange("Receipt Data Id", Rec.Id);
        CardReceiptParticipant.DeleteAll();
        CardReceiptItem.SetRange("Receipt Data Id", Rec.Id);
        CardReceiptItem.DeleteAll();
        CardReceiptVATSpec.SetRange("Receipt Data Id", Rec.Id);
        CardReceiptVATSpec.DeleteAll();
    end;
}
