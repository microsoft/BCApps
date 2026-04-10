// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using System.Utilities;

codeunit 884 "ReadSoft OCR Master Data Sync"
{
    Permissions = tabledata "OCR Service Setup" = rm;

    trigger OnRun()
    begin
    end;

    var
        OCRServiceSetup: Record "OCR Service Setup";
        OCRServiceMgt: Codeunit "OCR Service Mgt.";
        XmlOptions: XmlWriteOptions;
        WindowDialog: Dialog;
        SyncVendorsUriTxt: Label 'masterdata/rest/%1/suppliers', Locked = true;
        SyncVendorBankAccountsUriTxt: Label 'masterdata/rest/%1/supplierbankaccounts', Locked = true;
        SyncModifiedVendorsMsg: Label 'Send updated vendors to the OCR service.';
        SyncBankAccountsMsg: Label 'Send vendor bank accounts to the OCR service.';
        SyncSuccessfulSimpleMsg: Label 'Synchronization succeeded.';
        SyncSuccessfulDetailedMsg: Label 'Synchronization succeeded. Created: %1, Updated: %2, Deleted: %3', Comment = '%1 number of created entities, %2 number of updated entities, %3 number of deleted entities';
        SyncFailedSimpleMsg: Label 'Synchronization failed.';
        SyncFailedDetailedMsg: Label 'Synchronization failed. Code: %1, Message: %2', Comment = '%1 error code, %2 error message';
        InvalidResponseMsg: Label 'Response is invalid.';
        MasterDataSyncMsg: Label 'Master data synchronization.\#1########################################', Comment = '#1 place holder for SendingPackageMsg ';
        SendingPackageMsg: Label 'Sending package %1 of %2', Comment = '%1 package number, %2 package count';
        MaxPortionSizeTxt: Label '10000', Locked = true;
        MethodPutTok: Label 'PUT', Locked = true;
        MethodPostTok: Label 'POST', Locked = true;
        WindowUpdateDateTime: DateTime;
        OrganizationId: Text;
        PackageNo: Integer;
        PackageCount: Integer;
        MaxPortionSizeValue: Integer;
        OCRServiceMasterDataSyncSucceededTxt: Label 'Successfully synchronized %1 entities with OCR service.', Locked = true;
        OCRServiceMasterDataSyncFailedTxt: Label 'Failed to synchronize %1 entities with OCR service.', Locked = true;
        TelemetryCategoryTok: Label 'AL OCR Service', Locked = true;
        UpdateResultTagTxt: Label 'UpdateResult', Locked = true;
        ServiceErrorTagTxt: Label 'ServiceError', Locked = true;
        AdjustedBodyTxt: Label '<root>%1</root>', Locked = true;
        RequestTemplateTxt: label '<%1 xmlns:i="http://www.w3.org/2001/XMLSchema-instance">%2</%3>', Locked = true;
        CannotLoadXmlDocumentTxt: Label 'Cannot load XML document. Request type: %1, Reponse body: %2', Locked = true;
        CannotGetRootNodeTxt: Label 'Cannot get root node. Request type: %1, Response body: %2', Locked = true;
        CannotFindChildNodesTxt: Label 'Cannot find child nodes. Request type: %1, Response body: %2', Locked = true;
        ChildNodeCountTxt: Label 'There are multiple child elements. Request type: %1, Child count: %2, Response body: %3', Locked = true;
        ServiceErrorDetailsTxt: Label 'ServiceError response was parsed. Request type: %1, Response number: %2, Code: %3, Message: %4', Locked = true;
        ServiceErrorCannotParseTxt: Label 'Cannot parse ServiceError response. Request type: %1, Response number: %2, Response body: %3', Locked = true;
        UpdateResultCannotParseTxt: Label 'Cannot parse UpdateResult response. Request type: %1, Response number: %2, Response body: %3', Locked = true;
        XmlNameSpace: Text;
        CRLF: Text[2];
        CR: Text[1];
        LF: Text[1];

    procedure SyncMasterData(Resync: Boolean; Silent: Boolean): Boolean
    var
        LastSyncTime: DateTime;
        SyncStartTime: DateTime;
    begin
        OCRServiceMgt.GetOcrServiceSetupExtended(OCRServiceSetup, true);
        OCRServiceSetup.TestField("Master Data Sync Enabled");

        if Resync then begin
            Clear(OCRServiceSetup."Master Data Last Sync");
            OCRServiceSetup.Modify();
            Commit();
        end;

        Initialize();
        LastSyncTime := OCRServiceSetup."Master Data Last Sync";
        SyncStartTime := CurrentDateTime();

        if not SyncVendors(LastSyncTime, SyncStartTime) then begin
            if not Silent then
                Message(SyncFailedSimpleMsg);
            exit(false);
        end;

        OCRServiceSetup."Master Data Last Sync" := SyncStartTime;
        OCRServiceSetup.Modify();
        if not Silent then
            Message(SyncSuccessfulSimpleMsg);
        exit(true);
    end;

    procedure ResetLastSyncTime()
    begin
        if not IsSyncEnabled() then
            exit;
        OCRServiceSetup.Get();
        if OCRServiceSetup."Master Data Last Sync" = 0DT then
            exit;
        Clear(OCRServiceSetup."Master Data Last Sync");
        OCRServiceSetup.Modify();
        Commit();
    end;

    procedure IsSyncEnabled(): Boolean
    begin
        if not OCRServiceSetup.Get() then
            exit(false);

        if not OCRServiceSetup."Master Data Sync Enabled" then
            exit(false);

        if not OCRServiceSetup.Enabled then
            exit(false);

        if OCRServiceSetup."Service URL" = '' then
            exit(false);

        exit(true);
    end;

    local procedure CheckSyncResponse(ResponseBody: Text; RequestType: Text; ActivityDescription: Text): Boolean
    var
        XmlDoc: XmlDocument;
        RootXmlElement: XmlElement;
        XmlNodeList: XmlNodeList;
        XmlNode: XmlNode;
        AdjustedBody: Text;
        Count: Integer;
        Number: Integer;
    begin
        AdjustedBody := StrSubstNo(AdjustedBodyTxt, ResponseBody);
        if not TryLoadXml(AdjustedBody, XmlDoc) then begin
            ClearLastError();
            Session.LogMessage('0000DOD', StrSubstNo(CannotLoadXmlDocumentTxt, RequestType, ResponseBody), Verbosity::Normal, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            exit(false);
        end;
        if not XmlDoc.GetRoot(RootXmlElement) then begin
            Session.LogMessage('0000DOE', StrSubstNo(CannotGetRootNodeTxt, RequestType, ResponseBody), Verbosity::Normal, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            exit(false);
        end;
        XmlNodeList := RootXmlElement.GetChildNodes();
        Count := XmlNodeList.Count();
        if Count = 0 then begin
            Session.LogMessage('0000DOF', StrSubstNo(CannotFindChildNodesTxt, RequestType, ResponseBody), Verbosity::Normal, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            exit(false);
        end;
        if Count > 1 then
            Session.LogMessage('0000DOG', StrSubstNo(ChildNodeCountTxt, RequestType, Count, ResponseBody), Verbosity::Normal, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
        foreach XmlNode in XmlNodeList do begin
            Number += 1;
            case XmlNode.AsXmlElement().Name() of
                UpdateResultTagTxt:
                    ParseUpdateResult(XmlNode, RequestType, Number, ResponseBody, ActivityDescription);
                ServiceErrorTagTxt:
                    ParseServiceError(XmlNode, RequestType, Number, ResponseBody, ActivityDescription);
            end;
        end;
        exit(true);
    end;

    [TryFunction]
    local procedure TryLoadXml(XmlText: Text; var XmlDoc: XmlDocument)
    begin
        XmlDocument.ReadFrom(XmlText, XmlDoc);
    end;

    local procedure ParseUpdateResult(var UpdateResultXmlNode: XmlNode; RequestType: Text; Number: Integer; ResponseBody: Text; ActivityDescription: Text)
    var
        ChildXmlNode: XmlNode;
        NoOfCreated: Integer;
        NoOfUpdated: Integer;
        NoOfDeleted: Integer;
        ElementCount: Integer;
    begin
        if UpdateResultXmlNode.SelectSingleNode('Created', ChildXmlNode) then
            if ChildXmlNode.IsXmlElement() then
                if Evaluate(NoOfCreated, ChildXmlNode.AsXmlElement().InnerText(), 9) then
                    ElementCount += 1;
        if UpdateResultXmlNode.SelectSingleNode('Updated', ChildXmlNode) then
            if ChildXmlNode.IsXmlElement() then
                if Evaluate(NoOfUpdated, ChildXmlNode.AsXmlElement().InnerText(), 9) then
                    ElementCount += 1;
        if UpdateResultXmlNode.SelectSingleNode('Deleted', ChildXmlNode) then
            if ChildXmlNode.IsXmlElement() then
                if Evaluate(NoOfDeleted, ChildXmlNode.AsXmlElement().InnerText(), 9) then
                    ElementCount += 1;
        if ElementCount = 0 then
            Session.LogMessage('0000DOI', StrSubstNo(UpdateResultCannotParseTxt, RequestType, Number, ResponseBody), Verbosity::Normal, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
        OCRServiceMgt.LogActivitySucceeded(
          OCRServiceSetup.RecordId, ActivityDescription, StrSubstNo(SyncSuccessfulDetailedMsg, NoOfCreated, NoOfUpdated, NoOfDeleted));
    end;

    local procedure ParseServiceError(var ServiceErrorXmlNode: XmlNode; RequestType: Text; Number: Integer; ResponseBody: Text; ActivityDescription: Text)
    var
        ChildXmlNode: XmlNode;
        ErrorCode: Text;
        ErrorMessage: Text;
    begin
        if ServiceErrorXmlNode.SelectSingleNode('Code', ChildXmlNode) then
            if ChildXmlNode.IsXmlElement() then
                ErrorCode := ChildXmlNode.AsXmlElement().InnerText();
        if ServiceErrorXmlNode.SelectSingleNode('Message', ChildXmlNode) then
            if ChildXmlNode.IsXmlElement() then
                ErrorMessage := ChildXmlNode.AsXmlElement().InnerText();
        if (ErrorCode <> '') or (ErrorMessage <> '') then
            Session.LogMessage('0000DOL', StrSubstNo(ServiceErrorDetailsTxt, RequestType, Number, ErrorCode, ErrorMessage), Verbosity::Normal, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok)
        else
            Session.LogMessage('0000DOM', StrSubstNo(ServiceErrorCannotParseTxt, RequestType, Number, ResponseBody), Verbosity::Normal, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
        OCRServiceMgt.LogActivityFailed(
          OCRServiceSetup.RecordId, ActivityDescription, StrSubstNo(SyncFailedDetailedMsg, ErrorCode, ErrorMessage));
    end;

    local procedure SyncVendors(StartDateTime: DateTime; EndDateTime: DateTime): Boolean
    var
        ModifiedVendorTempBlobList: Codeunit "Temp Blob List";
        BankAccountTempBlobList: Codeunit "Temp Blob List";
        ModifiedVendorCount: Integer;
        BankAccountCount: Integer;
        ModifyVendorPackageCount: Integer;
        BankAccountPackageCount: Integer;
        TotalPackageCount: Integer;
        PortionSize: Integer;
        Success: Boolean;
        ModifiedVendorFirstPortionAction: Code[6];
    begin
        if StartDateTime > 0DT then
            ModifiedVendorFirstPortionAction := MethodPostTok
        else
            ModifiedVendorFirstPortionAction := MethodPutTok;

        GetModifiedVendors(ModifiedVendorTempBlobList, StartDateTime, EndDateTime);
        GetVendorBankAccounts(BankAccountTempBlobList, StartDateTime, EndDateTime);

        ModifiedVendorCount := ModifiedVendorTempBlobList.Count();
        BankAccountCount := BankAccountTempBlobList.Count();
        PortionSize := GetPortionSize();

        if (ModifiedVendorCount > 0) or (StartDateTime = 0DT) then begin
            ModifyVendorPackageCount := (ModifiedVendorCount div PortionSize);
            if (ModifiedVendorCount mod PortionSize) > 0 then
                ModifyVendorPackageCount += 1;
        end;
        if BankAccountCount > 0 then begin
            BankAccountPackageCount := (BankAccountCount div PortionSize);
            if (BankAccountCount mod PortionSize) > 0 then
                BankAccountPackageCount := 1;
        end;
        TotalPackageCount := ModifyVendorPackageCount + BankAccountPackageCount;

        if TotalPackageCount = 0 then
            exit(true);

        CheckOrganizationId();

        OpenWindow(TotalPackageCount);

        Success := SyncMasterDataEntities(
            ModifiedVendorTempBlobList, VendorsUri(), ModifiedVendorFirstPortionAction, MethodPostTok,
            'Suppliers', SyncModifiedVendorsMsg, PortionSize);

        if Success then
            Success := SyncMasterDataEntities(
                BankAccountTempBlobList, VendorBankAccountsUri(), MethodPutTok, MethodPutTok,
                'SupplierBankAccounts', SyncBankAccountsMsg, PortionSize);

        CloseWindow();

        exit(Success);
    end;

    local procedure SyncMasterDataEntities(var TempBlobList: Codeunit "Temp Blob List"; RequestUri: Text; FirstPortionAction: Code[6]; NextPortionAction: Code[6]; RootNodeName: Text; ActivityDescription: Text; PortionSize: Integer): Boolean
    var
        EntityCount: Integer;
        EntityNumber: Integer;
        PortionCount: Integer;
        PortionNumber: Integer;
        RequestAction: Code[6];
        RequestBody: Text;
        ResponseBody: Text;
        ErrorMessage: Text;
        ErrorDetails: Text;
        StatusCode: Integer;
    begin
        EntityCount := TempBlobList.Count();

        if EntityCount = 0 then begin
            if FirstPortionAction <> MethodPutTok then
                exit(true);
            PortionCount := 1;
            PortionSize := 0;
        end else begin
            PortionCount := EntityCount div PortionSize;
            if (EntityCount mod PortionSize) > 0 then
                PortionCount += 1;
        end;

        EntityNumber := 1;
        RequestAction := FirstPortionAction;
        for PortionNumber := 1 to PortionCount do begin
            UpdateWindow();
            ResponseBody := '';
            RequestBody := GetMasterDataEntitiesXml(TempBlobList, RootNodeName, PortionSize, EntityNumber);
            OnBeforeSendRequest(RequestBody);
            if not OCRServiceMgt.RsoRequest(RequestUri, RequestAction, RequestBody, ResponseBody, ErrorMessage, ErrorDetails, StatusCode) then begin
                LogTelemetryFailedMasterDataSync(RootNodeName);
                OCRServiceMgt.LogActivityFailed(OCRServiceSetup.RecordId, ActivityDescription, SyncFailedSimpleMsg);
                exit(false);
            end;
            if not CheckSyncResponse(ResponseBody, RootNodeName, ActivityDescription) then
                OCRServiceMgt.LogActivityFailed(OCRServiceSetup.RecordId, ActivityDescription, InvalidResponseMsg);
            if EntityNumber > EntityCount then
                break;
            RequestAction := NextPortionAction;
        end;
        LogTelemetrySuccessfulMasterDataSync(RootNodeName);
        exit(true);
    end;

    local procedure GetModifiedVendors(var TempBlobList: Codeunit "Temp Blob List"; StartDateTime: DateTime; EndDateTime: DateTime)
    var
        OCRVendors: Query "OCR Vendors";
        Data: Text;
    begin
        OCRVendors.SetRange(ModifiedAt, StartDateTime, EndDateTime);
        if OCRVendors.Open() then
            while OCRVendors.Read() do begin
                Data := GetModifiedVendorXml(OCRVendors);
                AddToBuffer(TempBlobList, Data);
            end;
    end;

    local procedure GetVendorBankAccounts(var TempBlobList: Codeunit "Temp Blob List"; StartDateTime: DateTime; EndDateTime: DateTime)
    var
        OCRVendorBankAccounts: Query "OCR Vendor Bank Accounts";
        VendorId: Guid;
        Data: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetVendorBankAccounts(TempBlobList, StartDateTime, EndDateTime, XmlOptions, IsHandled);
        if IsHandled then
            exit;

        OCRVendorBankAccounts.SetRange(ModifiedAt, StartDateTime, EndDateTime);
        if not OCRVendorBankAccounts.Open() then
            exit;

        while OCRVendorBankAccounts.Read() do begin
            if IsNullGuid(VendorId) then
                VendorId := OCRVendorBankAccounts.Id;
            if VendorId <> OCRVendorBankAccounts.Id then begin
                AddToBuffer(TempBlobList, Data);
                VendorId := OCRVendorBankAccounts.Id;
                Data := '';
            end;
            Data += GetVendorBankAccountXml(OCRVendorBankAccounts);
        end;
        AddToBuffer(TempBlobList, Data);
    end;

    local procedure Min(A: Integer; B: Integer): Integer
    begin
        if A < B then
            exit(A);
        exit(B);
    end;

    local procedure GetMasterDataEntitiesXml(var TempBlobList: Codeunit "Temp Blob List"; RootNodeName: Text; PortionSize: Integer; var EntityNumber: Integer): Text
    var
        TempBlob: Codeunit "Temp Blob";
        Data: Text;
        Index: Integer;
        MaxIndex: Integer;
    begin
        Data := '';
        MaxIndex := Min(EntityNumber + PortionSize - 1, TempBlobList.Count());
        for Index := EntityNumber to MaxIndex do begin
            TempBlobList.Get(Index, TempBlob);
            Data += GetFromBuffer(TempBlob);
        end;
        EntityNumber := Index + 1;
        Data := StrSubstNo(RequestTemplateTxt, RootNodeName, Data, RootNodeName);
        exit(Data);
    end;

    local procedure GetModifiedVendorXml(var OCRVendors: Query "OCR Vendors"): Text
    var
        XmlElem: XmlElement;
        Blocked: Boolean;
        Result: Text;
    begin
        Blocked := OCRVendors.Blocked <> OCRVendors.Blocked::" ";
        XmlElem := XmlElement.Create('Supplier');

        // when using XML as the input for API, the element order needs to match exactly
        AddElement(XmlElem, 'SupplierNumber', OCRVendors.No);
        AddElement(XmlElem, 'Name', OCRVendors.Name);
        AddElement(XmlElem, 'TaxRegistrationNumber', OCRVendors.VAT_Registration_No);
        AddElement(XmlElem, 'Street', OCRVendors.Address);
        AddElement(XmlElem, 'PostalCode', OCRVendors.Post_Code);
        AddElement(XmlElem, 'City', OCRVendors.City);
        AddElement(XmlElem, 'Blocked', Format(Blocked, 0, 9));
        AddElement(XmlElem, 'TelephoneNumber', OCRVendors.Phone_No);

        XmlElem.WriteTo(XmlOptions, Result);
        exit(Result);
    end;

    local procedure GetVendorBankAccountXml(var OCRVendorBankAccounts: Query "OCR Vendor Bank Accounts"): Text
    var
        XmlElem: XmlElement;
        Result: Text;
        AccountXml: Text;
    begin
        if (OCRVendorBankAccounts.Bank_Account_No = '') and
           (OCRVendorBankAccounts.IBAN = '')
        then
            exit('');

        // when using XML as the input for API, the element order needs to match exactly

        if OCRVendorBankAccounts.Bank_Account_No <> '' then begin
            XmlElem := XmlElement.Create('SupplierBankAccount');
            AddElement(XmlElem, 'BankName', OCRVendorBankAccounts.Name);
            AddElement(XmlElem, 'SupplierNumber', OCRVendorBankAccounts.No);
            AddElement(XmlElem, 'BankNumber', OCRVendorBankAccounts.Bank_Branch_No);
            AddElement(XmlElem, 'AccountNumber', OCRVendorBankAccounts.Bank_Account_No);
            XmlElem.WriteTo(XmlOptions, AccountXml);
            Result += AccountXml;
        end;

        if OCRVendorBankAccounts.IBAN <> '' then begin
            XmlElem := XmlElement.Create('SupplierBankAccount');
            AddElement(XmlElem, 'BankName', OCRVendorBankAccounts.Name);
            AddElement(XmlElem, 'SupplierNumber', OCRVendorBankAccounts.No);
            AddElement(XmlElem, 'BankNumberType', 'bic');
            AddElement(XmlElem, 'BankNumber', OCRVendorBankAccounts.SWIFT_Code);
            AddElement(XmlElem, 'AccountNumberType', 'iban');
            AddElement(XmlElem, 'AccountNumber', OCRVendorBankAccounts.IBAN);
            XmlElem.WriteTo(XmlOptions, AccountXml);
            Result += AccountXml;
        end;

        exit(Result);
    end;

    local procedure AddElement(var XmlElem: XmlElement; var XmlChildElem: XmlElement; Name: Text; Value: Text): Boolean
    begin
        XmlChildElem := XmlElement.Create(Name, XmlNameSpace, Value.Replace(CRLF, '').Replace(CR, '').Replace(LF, '').Trim());
        exit(XmlElem.Add(XmlChildElem));
    end;

    local procedure AddElement(var XmlElem: XmlElement; Name: Text; Value: Text): Boolean
    var
        XmlChildElem: XmlElement;
    begin
        exit(AddElement(XmlElem, XmlChildElem, Name, Value));
    end;

    local procedure Initialize()
    begin
        XmlOptions.PreserveWhitespace := true;
        XmlNameSpace := '';
        CRLF[1] := 13;
        CRLF[2] := 10;
        CR[1] := 13;
        LF[1] := 10;
    end;

    local procedure AddToBuffer(var TempBlobList: Codeunit "Temp Blob List"; Data: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
    begin
        TempBlob.CreateOutStream(OutStream);
        OutStream.WriteText(Data);
        TempBlobList.Add(TempBlob);
    end;

    local procedure GetFromBuffer(var TempBlob: Codeunit "Temp Blob"): Text
    var
        InStream: InStream;
        Data: Text;
        Line: Text;
    begin
        if not TempBlob.HasValue() then
            exit;
        TempBlob.CreateInStream(InStream);
        while InStream.ReadText(Line) > 0 do
            Data += Line;
        exit(Data);
    end;

    local procedure VendorsUri(): Text
    begin
        exit(StrSubstNo(SyncVendorsUriTxt, OrganizationId));
    end;

    local procedure VendorBankAccountsUri(): Text
    begin
        exit(StrSubstNo(SyncVendorBankAccountsUriTxt, OrganizationId));
    end;

    local procedure CheckOrganizationId()
    begin
        OrganizationId := OCRServiceSetup."Organization ID";
        if OrganizationId = '' then begin
            OCRServiceMgt.UpdateOrganizationInfo(OCRServiceSetup);
            OrganizationId := OCRServiceSetup."Organization ID";
        end;
        OCRServiceSetup.TestField("Organization ID");
    end;

    local procedure GetPortionSize(): Integer
    var
        PortionSize: Integer;
        DefaultPortionSize: Integer;
        Handled: Boolean;
    begin
        OnGetPortionSize(PortionSize, Handled);
        DefaultPortionSize := MaxPortionSize();
        if (not Handled) or (PortionSize <= 0) or (PortionSize > MaxPortionSize()) then
            PortionSize := DefaultPortionSize;
        exit(PortionSize);
    end;

    local procedure MaxPortionSize(): Integer
    begin
        if MaxPortionSizeValue = 0 then
            Evaluate(MaxPortionSizeValue, MaxPortionSizeTxt);
        exit(MaxPortionSizeValue);
    end;

    local procedure OpenWindow("Count": Integer)
    begin
        PackageNo := 0;
        PackageCount := Count;
        WindowUpdateDateTime := CurrentDateTime;
        WindowDialog.Open(MasterDataSyncMsg);
        WindowDialog.Update(1, '');
    end;

    local procedure UpdateWindow()
    begin
        PackageNo += 1;
        if CurrentDateTime - WindowUpdateDateTime >= 300 then begin
            WindowUpdateDateTime := CurrentDateTime;
            WindowDialog.Update(1, StrSubstNo(SendingPackageMsg, PackageNo, PackageCount));
        end;
    end;

    local procedure CloseWindow()
    begin
        WindowDialog.Close();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendRequest(Body: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetVendorBankAccounts(var TempBlobList: Codeunit "Temp Blob List"; StartDateTime: DateTime; EndDateTime: DateTime; var XmlOptions: XmlWriteOptions; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPortionSize(var PortionSize: Integer; var Handled: Boolean)
    begin
    end;

    local procedure LogTelemetrySuccessfulMasterDataSync(RootNodeName: Text)
    begin
        Session.LogMessage('00008A3', StrSubstNo(OCRServiceMasterDataSyncSucceededTxt, RootNodeName), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
    end;

    local procedure LogTelemetryFailedMasterDataSync(RootNodeName: Text)
    begin
        Session.LogMessage('00008AJ', StrSubstNo(OCRServiceMasterDataSyncFailedTxt, RootNodeName), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
    end;
}

