// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 144083 "UT IT Transfer Shipment"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";

    [Test]
    [HandlerFunctions('SubcontractTransferShipmentRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SubcontractTransferShipmentRunsWhenLegacySubcontractingIsDisabled()
    var
        CompanyInformation: Record "Company Information";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        TransferShipmentLine: Record "Transfer Shipment Line";
#if not CLEAN28
        ManufacturingSetup: Record "Manufacturing Setup";
#endif
    begin
        // [SCENARIO 649580] The Italian transfer shipment report remains available when Legacy Subcontracting is disabled.
#if not CLEAN28
        if not ManufacturingSetup.Get() then begin
            ManufacturingSetup.Init();
            ManufacturingSetup.Insert();
        end;
        ManufacturingSetup."Legacy Subcontracting" := false;
        ManufacturingSetup.Modify();
#endif
        if not CompanyInformation.Get() then begin
            CompanyInformation.Init();
            CompanyInformation.Insert();
        end;

        TransferShipmentHeader."No." := LibraryRandom.RandText(MaxStrLen(TransferShipmentHeader."No."));
        TransferShipmentHeader."Goods Appearance" := LibraryRandom.RandText(MaxStrLen(TransferShipmentHeader."Goods Appearance"));
        TransferShipmentHeader.Insert();

        TransferShipmentLine."Document No." := TransferShipmentHeader."No.";
        TransferShipmentLine."Line No." := 10000;
        TransferShipmentLine.Description := LibraryRandom.RandText(MaxStrLen(TransferShipmentLine.Description));
        TransferShipmentLine.Quantity := LibraryRandom.RandDec(10, 2);
        TransferShipmentLine.Insert();

        LibraryVariableStorage.Enqueue(TransferShipmentHeader."No.");

        Report.Run(Report::"Subcontract. Transfer Shipment");

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
            'Transfer_Shipment_Header_No_', TransferShipmentHeader."No.");
        LibraryReportDataset.AssertElementWithValueExists(
            'Transfer_Shipment_Header___Goods_Appearance_', TransferShipmentHeader."Goods Appearance");
        LibraryVariableStorage.AssertEmpty();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SubcontractTransferShipmentRequestPageHandler(var SubcontractTransferShipment: TestRequestPage "Subcontract. Transfer Shipment")
    var
        TransferShipmentNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(TransferShipmentNo);
        SubcontractTransferShipment."Transfer Shipment Header".SetFilter("No.", TransferShipmentNo);
        SubcontractTransferShipment.SaveAsXml(
            LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}
