// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Test;

using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Item;

codeunit 134156 "Service Table Fields UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [UT] [Service]
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryService: Codeunit "Library - Service";
        LibrarySales: Codeunit "Library - Sales";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceCrMemoHeader_Amount()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceCrMemoLine: array[3] of Record "Service Cr.Memo Line";
    begin
        // [SCENARIO 270180] Service Cr. Memo Header has got Amount flow field showing sum of Amount of its lines.
        MockServiceCrMemoHeader(ServiceCrMemoHeader);
        MockServiceCrMemoLine(ServiceCrMemoLine[1], ServiceCrMemoHeader);

        MockServiceCrMemoHeader(ServiceCrMemoHeader);
        MockServiceCrMemoLine(ServiceCrMemoLine[2], ServiceCrMemoHeader);
        MockServiceCrMemoLine(ServiceCrMemoLine[3], ServiceCrMemoHeader);

        ServiceCrMemoHeader.CalcFields(Amount, "Amount Including VAT");

        ServiceCrMemoHeader.TestField(Amount, ServiceCrMemoLine[2].Amount + ServiceCrMemoLine[3].Amount);
        ServiceCrMemoHeader.TestField(
          "Amount Including VAT",
          ServiceCrMemoLine[2]."Amount Including VAT" + ServiceCrMemoLine[3]."Amount Including VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RunIsCreditTypeOnServiceDocumentsUT()
    var
        ServiceHeader: Record "Service Header";
        CustomerNo: Code[20];
    begin
        // [SCENARIO 378446] Run IsCreditType function of Service Header table on Service Documents.
        Initialize();
        CustomerNo := LibrarySales.CreateCustomerNo();

        // [GIVEN] Service Invoice.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, CustomerNo);

        // [WHEN] Run IsCreditType function on Service Invoice.
        // [THEN] The function retuns False.
        Assert.IsFalse(ServiceHeader.IsCreditDocType(), '');

        // [GIVEN] Service Order.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CustomerNo);

        // [WHEN] Run IsCreditType function on Service Order.
        // [THEN] The function retuns False.
        Assert.IsFalse(ServiceHeader.IsCreditDocType(), '');

        // [GIVEN] Service Quote.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Quote, CustomerNo);

        // [WHEN] Run IsCreditType function on Service Quote.
        // [THEN] The function retuns False.
        Assert.IsFalse(ServiceHeader.IsCreditDocType(), '');

        // [GIVEN] Service Credit Memo.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", CustomerNo);

        // [WHEN] Run IsCreditType function on Service Credit Memo.
        // [THEN] The function retuns True.
        Assert.IsTrue(ServiceHeader.IsCreditDocType(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StandardServiceItemGrCodeOnDelete()
    var
        StandardServiceCode: Record "Standard Service Code";
        StandardServiceLine: Record "Standard Service Line";
        StandardServiceItemGrCode: Record "Standard Service Item Gr. Code";
    begin
        // [SCENARIO 395389] System keeps standard sevice lines when users deletes standard service item group code.
        StandardServiceCode.Init();
        StandardServiceCode.Code := LibraryUtility.GenerateGUID();
        StandardServiceCode.Insert();

        StandardServiceLine.Init();
        StandardServiceLine."Standard Service Code" := StandardServiceCode.Code;
        StandardServiceLine."Line No." := 10000;
        StandardServiceLine.Insert();

        StandardServiceItemGrCode.Init();
        StandardServiceItemGrCode."Service Item Group Code" := LibraryUtility.GenerateGUID();
        StandardServiceItemGrCode.Code := StandardServiceCode.Code;
        StandardServiceItemGrCode.Insert();

        StandardServiceItemGrCode.Delete(true);

        StandardServiceLine.SetRange("Standard Service Code", StandardServiceCode.Code);
        Assert.RecordCount(StandardServiceLine, 1);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Service Table Fields UT");
        if IsInitialized then
            exit;

        LibraryService.SetupServiceMgtNoSeries();

        IsInitialized := true;
    end;

    local procedure MockServiceCrMemoHeader(var ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    begin
        ServiceCrMemoHeader.Init();
        ServiceCrMemoHeader."No." :=
          LibraryUtility.GenerateRandomCode20(ServiceCrMemoHeader.FieldNo("No."), DATABASE::"Service Cr.Memo Header");
        ServiceCrMemoHeader.Insert();
    end;

    local procedure MockServiceCrMemoLine(var ServiceCrMemoLine: Record "Service Cr.Memo Line"; ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    begin
        ServiceCrMemoLine.Init();
        ServiceCrMemoLine."Document No." := ServiceCrMemoHeader."No.";
        ServiceCrMemoLine."Line No." :=
          LibraryUtility.GetNewRecNo(ServiceCrMemoLine, ServiceCrMemoLine.FieldNo("Line No."));
        ServiceCrMemoLine.Insert();
        ServiceCrMemoLine.Amount := LibraryRandom.RandIntInRange(10, 20);
        ServiceCrMemoLine."Amount Including VAT" := LibraryRandom.RandIntInRange(10, 20);
        ServiceCrMemoLine.Modify();
    end;
}

