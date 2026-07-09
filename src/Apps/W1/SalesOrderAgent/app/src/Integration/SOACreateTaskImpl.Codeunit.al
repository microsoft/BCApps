// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.SalesOrderAgent;

using Microsoft.CRM.Contact;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Item;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using System.Agents;
using System.Security.User;
using System.Utilities;

codeunit 4415 "SOA Create Task Impl"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    internal procedure SetAgentUserSecurityID(NewAgentUserSecurityID: Guid)
    begin
        GlobalAgentUserSecurityID := NewAgentUserSecurityID;
    end;

    internal procedure GetCurrentUserSalespersonCode(): Code[20]
    var
        UserSetup: Record "User Setup";
    begin
        if UserSetup.Get(UserId()) then
            exit(UserSetup."Salespers./Purch. Code");
    end;

    internal procedure SetSelectedContact(Contact: Record Contact)
    begin
        SetSampleSenderFields(
            Contact.Name, Contact."E-Mail", Contact."Company Name",
            Contact.Address, Contact."Post Code", Contact.City, Contact."Phone No.", Contact."Language Code");
        ResolveLocationCodeFromContact(Contact);
        SelectedContactNo := Contact."No.";
        SelectedCustomerNo := '';
        Clear(CachedAvailBalance);
    end;

    internal procedure SetSelectedCustomer(Customer: Record Customer)
    begin
        SetSampleSenderFields(
            Customer.Name, Customer."E-Mail", Customer.Name,
            Customer.Address, Customer."Post Code", Customer.City, Customer."Phone No.", Customer."Language Code");
        ResolveLocationCodeFromCustomer(Customer);
        SelectedCustomerNo := Customer."No.";
        SelectedContactNo := '';
        Clear(CachedAvailBalance);
    end;

    internal procedure ClearSelectedSender()
    begin
        SelectedContactNo := '';
        SelectedCustomerNo := '';
        SelectedLocationCode := '';
        SelectedLanguageCode := '';
        SampleSenderName := '';
        SampleSenderEmail := '';
        SampleSenderCompany := '';
        SampleSenderAddress := '';
        SampleSenderCity := '';
        SampleSenderPhone := '';
        Clear(CachedAvailBalance);
    end;

    internal procedure CreateTask(SenderEmail: Text[250]; MessageText: Text; var TempAgentTaskFile: Record "Agent Task File" temporary)
    var
        SOASetup: Record "SOA Setup";
        SOARetrieveEmails: Codeunit "SOA Retrieve Emails";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        AgentTaskMessageBuilder: Codeunit "Agent Task Message Builder";
        AgentTaskTitle: Text[150];
    begin
        if SenderEmail = '' then
            Error(YouMustSetSenderEmailErr);

        if MessageText = '' then
            Error(YouMustSetMessageTextErr);

        SOASetup.SetRange("User Security ID", GlobalAgentUserSecurityID);
        if not SOASetup.FindFirst() then
            Error(SOASetupNotFoundErr);

        AgentTaskTitle := SOARetrieveEmails.GetAgentTaskTitle(SenderEmail);
        AgentTaskMessageBuilder.Initialize(SenderEmail, MessageText).SetIgnoreAttachment(not SOASetup."Analyze Attachments");
        AddAttachmentsToTaskMessage(AgentTaskMessageBuilder, TempAgentTaskFile);
        AgentTaskBuilder.Initialize(SOASetup."User Security ID", AgentTaskTitle).AddTaskMessage(AgentTaskMessageBuilder);
        AgentTaskBuilder.Create();
    end;

    local procedure AddAttachmentsToTaskMessage(AgentTaskMessageBuilder: Codeunit "Agent Task Message Builder"; var TempAgentTaskFile: Record "Agent Task File" temporary)
    begin
        if not TempAgentTaskFile.FindSet() then
            exit;

        repeat
            AgentTaskMessageBuilder.AddAttachment(TempAgentTaskFile);
        until TempAgentTaskFile.Next() = 0;
    end;

    internal procedure LoadSampleMessage(SenderEmail: Text[250]; var MessageText: Text)
    var
        SenderName: Text[250];
    begin
        SyncSelectionWithSenderEmail(SenderEmail);
        SenderName := GetSampleSenderName(SenderEmail);
        MessageText := StrSubstNo(
            SampleMessageTok, HtmlEncode(GreetingTxt), HtmlEncode(RequestItemsTxt),
            GetSampleItemsHtml(), HtmlEncode(RequestBodyTxt), HtmlEncode(ThankYouTxt), HtmlEncode(SenderName));
    end;

    internal procedure LoadSampleMessageWithAttachment(SenderEmail: Text[250]; var MessageText: Text; var TempBlob: Codeunit "Temp Blob")
    var
        SenderName: Text[250];
    begin
        SyncSelectionWithSenderEmail(SenderEmail);
        SenderName := GetSampleSenderName(SenderEmail);
        MessageText := StrSubstNo(
            SampleMessageWithAttachmentTok, HtmlEncode(GreetingTxt),
            HtmlEncode(RequestAttachmentTxt), HtmlEncode(ThankYouTxt), HtmlEncode(SenderName));
        EnsureSampleSenderDefaults(SenderEmail, SenderName);
        GenerateSampleOrderPdf(TempBlob);
    end;

    internal procedure GetSampleAttachmentName(): Text
    begin
        exit(SampleAttachmentNameTok);
    end;

    internal procedure GetSampleAttachmentMimeType(): Text
    begin
        exit(SampleAttachmentMimeTok);
    end;

    local procedure ResolveLocationCodeFromContact(Contact: Record Contact)
    var
        Customer: Record Customer;
    begin
        SelectedLocationCode := '';
        if Contact.FindCustomer(Customer) then
            ResolveLocationCodeFromCustomer(Customer);
    end;

    local procedure ResolveLocationCodeFromCustomer(Customer: Record Customer)
    begin
        SelectedLocationCode := Customer.GetDefaultLocation();
    end;

    local procedure GenerateSampleOrderPdf(var TempBlob: Codeunit "Temp Blob")
    var
        SOASampleOrder: Report "SOA Sample Order";
        OutStream: OutStream;
    begin
        TempBlob.CreateOutStream(OutStream);
        SOASampleOrder.SetSender(
            SampleSenderCompany, SampleSenderName, SampleSenderAddress,
            SampleSenderCity, SampleSenderPhone, SampleSenderEmail);
        SOASampleOrder.SetLocationCode(SelectedLocationCode);
        SOASampleOrder.SetLanguageCode(SelectedLanguageCode);
        SOASampleOrder.SetItemFilter(BuildItemNoFilter(GetSampleItemNos()));
        SOASampleOrder.SaveAs('', ReportFormat::Pdf, OutStream);
    end;

    local procedure BuildItemNoFilter(ItemNos: List of [Code[20]]): Text
    var
        FilterBuilder: TextBuilder;
        ItemNo: Code[20];
    begin
        foreach ItemNo in ItemNos do begin
            if FilterBuilder.Length() > 0 then
                FilterBuilder.Append('|');
            FilterBuilder.Append(ItemNo);
        end;
        exit(FilterBuilder.ToText());
    end;

    local procedure GetSampleSenderName(SenderEmail: Text[250]): Text[250]
    begin
        if SampleSenderName <> '' then
            exit(SampleSenderName);
        exit(GetSenderNameFromEmail(SenderEmail));
    end;

    local procedure EnsureSampleSenderDefaults(SenderEmail: Text[250]; SenderName: Text[250])
    begin
        if SampleSenderEmail = '' then
            SampleSenderEmail := SenderEmail;
        if SampleSenderName = '' then
            SampleSenderName := SenderName;
        if SampleSenderCompany = '' then
            SampleSenderCompany := SampleSenderName;
    end;

    local procedure SyncSelectionWithSenderEmail(SenderEmail: Text[250])
    begin
        if (SampleSenderEmail <> '') and (SampleSenderEmail <> SenderEmail) then
            ClearSelectedSender();
    end;

    local procedure SetSampleSenderFields(Name: Text; Email: Text; Company: Text; Address: Text; PostCode: Text; City: Text; Phone: Text; LanguageCode: Code[10])
    begin
        SampleSenderName := CopyStr(Name, 1, MaxStrLen(SampleSenderName));
        SampleSenderEmail := CopyStr(Email, 1, MaxStrLen(SampleSenderEmail));
        SampleSenderCompany := CopyStr(Company, 1, MaxStrLen(SampleSenderCompany));
        SampleSenderAddress := CopyStr(Address, 1, MaxStrLen(SampleSenderAddress));
        SampleSenderCity := CopyStr(DelChr(PostCode + ' ' + City, '<>', ' '), 1, MaxStrLen(SampleSenderCity));
        SampleSenderPhone := CopyStr(Phone, 1, MaxStrLen(SampleSenderPhone));
        SelectedLanguageCode := LanguageCode;
    end;

    local procedure IncrementCount(var Counts: Dictionary of [Code[20], Integer]; CountKey: Code[20]): Integer
    var
        CurrentCount: Integer;
    begin
        if Counts.Get(CountKey, CurrentCount) then
            CurrentCount += 1
        else
            CurrentCount := 1;
        Counts.Set(CountKey, CurrentCount);
        exit(CurrentCount);
    end;

    internal procedure GetSampleLineQuantity(SourceItem: Record Item; LocationCode: Code[10]): Integer
    begin
        exit(QuantityFromAvailableBalance(CalcItemProjAvailableBalance(SourceItem, LocationCode)));
    end;

    local procedure CalcItemProjAvailableBalance(SourceItem: Record Item; LocationCode: Code[10]): Decimal
    var
        Item: Record Item;
        ItemAvailFormsMgt: Codeunit "Item Availability Forms Mgt";
        GrossRequirement: Decimal;
        PlannedOrderRcpt: Decimal;
        ScheduledRcpt: Decimal;
        PlannedOrderReleases: Decimal;
        ProjAvailableBalance: Decimal;
        ExpectedInventory: Decimal;
        DummyQtyAvailable: Decimal;
        AvailableInventory: Decimal;
    begin
        if SourceItem.Type <> SourceItem.Type::Inventory then
            exit(0);

        if CachedAvailBalance.Get(SourceItem."No.", ProjAvailableBalance) then
            exit(ProjAvailableBalance);

        Item.Copy(SourceItem);
        Item.SetRange("Date Filter", 0D, CalcDate('<CW+1W>', WorkDate()));
        Item.SetFilter("Location Filter", LocationCode);
        Item.SetRange("Drop Shipment Filter", false);
        Item.SetRange("Variant Filter", '');

        ItemAvailFormsMgt.CalcAvailQuantities(Item, true,
            GrossRequirement, PlannedOrderRcpt, ScheduledRcpt,
            PlannedOrderReleases, ProjAvailableBalance, ExpectedInventory,
            DummyQtyAvailable, AvailableInventory);
        CachedAvailBalance.Set(SourceItem."No.", ProjAvailableBalance);
        exit(ProjAvailableBalance);
    end;

    local procedure QuantityFromAvailableBalance(AvailableQty: Decimal): Integer
    var
        MaxQty: Integer;
    begin
        MaxQty := Round(AvailableQty, 1, '<');
        if MaxQty < 1 then
            MaxQty := 1;
        if MaxQty > 10 then
            MaxQty := 10;
        exit(Random(MaxQty));
    end;

    local procedure GetSenderNameFromEmail(Email: Text[250]): Text[250]
    var
        AtPos: Integer;
    begin
        AtPos := StrPos(Email, '@');
        if AtPos > 1 then
            exit(CopyStr(CopyStr(Email, 1, AtPos - 1), 1, MaxStrLen(SampleSenderName)));
        exit(CopyStr(DefaultSenderNameTxt, 1, MaxStrLen(SampleSenderName)));
    end;

    local procedure GetSampleItemsHtml(): Text
    var
        Item: Record Item;
        ItemNos: List of [Code[20]];
        ItemsBuilder: TextBuilder;
        ItemNo: Code[20];
    begin
        ItemNos := GetSampleItemNos();
        foreach ItemNo in ItemNos do
            if Item.Get(ItemNo) then
                ItemsBuilder.Append(StrSubstNo(SampleItemLineTok, GetSampleLineQuantity(Item, SelectedLocationCode), HtmlEncode(Item.Description)));

        if ItemsBuilder.Length() = 0 then
            exit(SampleFallbackItemsTok);

        exit(ItemsBuilder.ToText());
    end;

    local procedure HtmlEncode(Value: Text): Text
    begin
        Value := Value.Replace('&', '&amp;');
        Value := Value.Replace('<', '&lt;');
        Value := Value.Replace('>', '&gt;');
        Value := Value.Replace('"', '&quot;');
        Value := Value.Replace('''', '&#39;');
        exit(Value);
    end;

    local procedure GetSampleItemNos(): List of [Code[20]]
    var
        ItemNos: List of [Code[20]];
    begin
        ItemNos := GetTopSampleItemNos();
        if ItemNos.Count() = 0 then
            ItemNos := GetFallbackItemNos();
        exit(ItemNos);
    end;

    local procedure GetFallbackItemNos(): List of [Code[20]]
    var
        Item: Record Item;
        ItemNos: List of [Code[20]];
        BackupItemNos: List of [Code[20]];
        ProcessedCount: Integer;
    begin
        Item.SetRange(Type, Item.Type::Inventory);
        Item.SetRange(Blocked, false);
        Item.SetRange("Sales Blocked", false);
        Item.SetLoadFields("No.", Type);
        if Item.FindSet() then
            repeat
                ProcessedCount += 1;
                if BackupItemNos.Count() < 5 then
                    BackupItemNos.Add(Item."No.");
                if CalcItemProjAvailableBalance(Item, SelectedLocationCode) > 0 then
                    ItemNos.Add(Item."No.");
            until (Item.Next() = 0) or (ItemNos.Count() >= 5) or (ProcessedCount >= 200);

        if ItemNos.Count() = 0 then
            exit(BackupItemNos);
        exit(ItemNos);
    end;

    local procedure GetTopSampleItemNos(): List of [Code[20]]
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        Item: Record Item;
        ItemUsage: Dictionary of [Code[20], Integer];
        ItemNos: List of [Code[20]];
        ItemNo: Code[20];
        BestItemNo: Code[20];
        CurrentCount: Integer;
        BestCount: Integer;
        ProcessedCount: Integer;
    begin
        if (SelectedContactNo = '') and (SelectedCustomerNo = '') then
            exit(ItemNos);

        SalesShipmentHeader.SetCurrentKey("Posting Date");
        SalesShipmentHeader.SetAscending("Posting Date", false);
        if SelectedContactNo <> '' then
            SalesShipmentHeader.SetRange("Sell-to Contact No.", SelectedContactNo)
        else
            if SelectedCustomerNo <> '' then
                SalesShipmentHeader.SetRange("Sell-to Customer No.", SelectedCustomerNo);

        SalesShipmentHeader.SetLoadFields("No.");
        SalesShipmentLine.SetLoadFields("No.");
        if SalesShipmentHeader.FindSet() then
            repeat
                ProcessedCount += 1;
                SalesShipmentLine.SetRange("Document No.", SalesShipmentHeader."No.");
                SalesShipmentLine.SetRange(Type, SalesShipmentLine.Type::Item);
                SalesShipmentLine.SetFilter("No.", '<>%1', '');
                if SalesShipmentLine.FindSet() then
                    repeat
                        IncrementCount(ItemUsage, SalesShipmentLine."No.");
                    until SalesShipmentLine.Next() = 0;
            until (SalesShipmentHeader.Next() = 0) or (ProcessedCount >= 100);

        while (ItemNos.Count() < 5) and (ItemUsage.Count() > 0) do begin
            BestCount := 0;
            BestItemNo := '';
            foreach ItemNo in ItemUsage.Keys() do begin
                CurrentCount := ItemUsage.Get(ItemNo);
                if CurrentCount > BestCount then begin
                    BestCount := CurrentCount;
                    BestItemNo := ItemNo;
                end;
            end;
            if BestItemNo = '' then
                exit(ItemNos);
            ItemUsage.Remove(BestItemNo);

            if Item.Get(BestItemNo) and (not Item.Blocked) and (not Item."Sales Blocked") then
                if CalcItemProjAvailableBalance(Item, SelectedLocationCode) > 0 then
                    ItemNos.Add(BestItemNo);
        end;

        exit(ItemNos);
    end;

    var
        GlobalAgentUserSecurityID: Guid;
        CachedAvailBalance: Dictionary of [Code[20], Decimal];
        SelectedLocationCode: Code[10];
        SelectedLanguageCode: Code[10];
        SelectedContactNo: Code[20];
        SelectedCustomerNo: Code[20];
        SampleSenderName: Text[250];
        SampleSenderEmail: Text[250];
        SampleSenderCompany: Text[250];
        SampleSenderAddress: Text[250];
        SampleSenderCity: Text[250];
        SampleSenderPhone: Text[250];
        YouMustSetSenderEmailErr: Label 'You must specify the sender''s email.';
        YouMustSetMessageTextErr: Label 'You must specify the message text.';
        SOASetupNotFoundErr: Label 'SOA Setup is not configured for the current agent user.';
        DefaultSenderNameTxt: Label 'Customer';
        SampleMessageTok: Label '<p>%1</p><p>%2</p><ul>%3</ul><p>%4</p><p>%5<br>%6</p>', Locked = true, Comment = '%1 = greeting, %2 = intro line, %3 = HTML list (<li> elements) of requested items, %4 = closing line, %5 = thank-you line, %6 = sender name';
        SampleItemLineTok: Label '<li>%1 x %2</li>', Locked = true, Comment = '%1 = requested quantity (integer), %2 = item description';
        SampleFallbackItemsTok: Label '<li>5 x ATHENS Mobile Pedestal</li><li>2 x LONDON Swivel Chair, blue</li>', Locked = true;
        SampleMessageWithAttachmentTok: Label '<p>%1</p><p>%2</p><p>%3<br>%4</p>', Locked = true, Comment = '%1 = greeting, %2 = attachment intro line, %3 = thank-you line, %4 = sender name';
        GreetingTxt: Label 'Hello,';
        RequestItemsTxt: Label 'Please send me a quote for the following items:';
        RequestBodyTxt: Label 'I would need them by the end of next week, so please let me know your prices and whether they would be available by then.';
        RequestAttachmentTxt: Label 'Please send me a quote for the items in the attached file.';
        ThankYouTxt: Label 'Thank you,';
        SampleAttachmentNameTok: Label 'sample-order.pdf', Locked = true;
        SampleAttachmentMimeTok: Label 'application/pdf', Locked = true;
}
