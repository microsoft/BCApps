// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Outlook;

using Microsoft.Sales.Posting;

codeunit 1629 "Office Attachment Manager"
{
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        ContentString: Text;
        NameString: Text;
        Body: Text;
        "Count": Integer;

    procedure Add(FileContent: Text; FileName: Text; BodyText: Text)
    begin
        if ContentString <> '' then begin
            ContentString += '|';
            NameString += '|';
        end;

        ContentString += FileContent;
        NameString += FileName;
        if Body = '' then
            Body := BodyText;
        Count -= 1;
    end;

    procedure Ready(): Boolean
    begin
        exit(Count < 1);
    end;

    procedure Done()
    begin
        Count := 0;
        ContentString := '';
        NameString := '';
        Body := '';
    end;

    procedure GetFiles(): Text
    begin
        exit(ContentString);
    end;

    procedure GetNames(): Text
    begin
        exit(NameString);
    end;

    [Scope('OnPrem')]
    procedure GetBody(): Text
    begin
        exit(Body);
    end;

    procedure IncrementCount(NewCount: Integer)
    begin
        Count += NewCount;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnSendSalesDocument', '', false, false)]
    local procedure OnSendSalesDocument(ShipAndInvoice: Boolean)
    begin
        if ShipAndInvoice then
            Count := 2;
    end;
}

