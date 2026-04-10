// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Test;

using Microsoft.Sales.Document;
using Microsoft.Sales.History;

codeunit 136116 "Service Removal From Sales"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Removal from Sales] [Service]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        FieldMustNotExistError: Label '%1 Field must not Exist.';
        ServiceMgtDocument: Label 'Service Mgt. Document';
        ServiceContractNo: Label 'Service Contract No.';
        ServiceOrderNo: Label 'Service Order No.';
        ServiceItemNo: Label 'Service Item No.';
        AppltoServiceEntry: Label 'Appl.-to Service Entry';
        ServiceItemLineNo: Label 'Service Item Line No.';
        ServPriceAdjmtGrCode: Label 'Serv. Price Adjmt. Gr. Code';
        Initialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceMgtDocumentOnHeader()
    begin
        // Covers document number TC-PP-RS-1 - refer to TFS ID 20926.
        // Test that Service Mgt. Document Field is removed from the Sales Header.

        CheckFieldOnSalesTable(DATABASE::"Sales Header", ServiceMgtDocument);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceMgtDocumentOnShipHeader()
    begin
        // Covers document number TC-PP-RS-2 - refer to TFS ID 20926.
        // Test that Service Mgt. Document Field is removed from the Sales Shipment Header.

        CheckFieldOnSalesTable(DATABASE::"Sales Shipment Header", ServiceMgtDocument);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceMgtDocumentOnInvHeader()
    begin
        // Covers document number TC-PP-RS-3 - refer to TFS ID 20926.
        // Test that Service Mgt. Document Field is removed from the Sales Invoice Header.

        CheckFieldOnSalesTable(DATABASE::"Sales Invoice Header", ServiceMgtDocument);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceMgtDocumentCrMemoHeader()
    begin
        // Covers document number TC-PP-RS-4 - refer to TFS ID 20926.
        // Test that Service Mgt. Document Field is removed from the Sales Cr.Memo Header.

        CheckFieldOnSalesTable(DATABASE::"Sales Cr.Memo Header", ServiceMgtDocument);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceContactNoOnLine()
    begin
        // Covers document number TC-PP-RS-5 - refer to TFS ID 20926.
        // Test that Service Contract No. Field is removed from the Sales Line.

        CheckFieldOnSalesTable(DATABASE::"Sales Line", ServiceContractNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderNoOnLine()
    begin
        // Covers document number TC-PP-RS-5 - refer to TFS ID 20926.
        // Test that Service Order No. Field is removed from the Sales Line.

        CheckFieldOnSalesTable(DATABASE::"Sales Line", ServiceOrderNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceItemNoOnLine()
    begin
        // Covers document number TC-PP-RS-5 - refer to TFS ID 20926.
        // Test that Service Item No. Field is removed from the Sales Line.

        CheckFieldOnSalesTable(DATABASE::"Sales Line", ServiceItemNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AppltoServiceEntryOnLine()
    begin
        // Covers document number TC-PP-RS-5 - refer to TFS ID 20926.
        // Test that Appl.-to Service Entry Field is removed from the Sales Line.

        CheckFieldOnSalesTable(DATABASE::"Sales Line", AppltoServiceEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceItemLineNoOnLine()
    begin
        // Covers document number TC-PP-RS-5 - refer to TFS ID 20926.
        // Test that Service Item Line No. Field is removed from the Sales Line.

        CheckFieldOnSalesTable(DATABASE::"Sales Line", ServiceItemLineNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServPriceAdjmtGrCodeOnLine()
    begin
        // Covers document number TC-PP-RS-5 - refer to TFS ID 20926.
        // Test that Serv. Price Adjmt. Gr. Code Field is removed from the Sales Line.

        CheckFieldOnSalesTable(DATABASE::"Sales Line", ServPriceAdjmtGrCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceContactNoOnInvLine()
    begin
        // Covers document number TC-PP-RS-6 - refer to TFS ID 20926.
        // Test that Service Contract No. Field is removed from the Sales Invoice Line.

        CheckFieldOnSalesTable(DATABASE::"Sales Invoice Line", ServiceContractNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderNoOnInvLine()
    begin
        // Covers document number TC-PP-RS-6 - refer to TFS ID 20926.
        // Test that Service Order No. Field is removed from the Sales Invoice Line.

        CheckFieldOnSalesTable(DATABASE::"Sales Invoice Line", ServiceOrderNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceItemNoOnInvLine()
    begin
        // Covers document number TC-PP-RS-6 - refer to TFS ID 20926.
        // Test that Service Item No. Field is removed from the Sales Invoice Line.

        CheckFieldOnSalesTable(DATABASE::"Sales Invoice Line", ServiceItemNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AppltoServiceEntryOnInvLine()
    begin
        // Covers document number TC-PP-RS-6 - refer to TFS ID 20926.
        // Test that Appl.-to Service Entry Field is removed from the Sales Invoice Line.

        CheckFieldOnSalesTable(DATABASE::"Sales Invoice Line", AppltoServiceEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceItemLineNoOnInvLine()
    begin
        // Covers document number TC-PP-RS-6 - refer to TFS ID 20926.
        // Test that Service Item Line No. Field is removed from the Sales Invoice Line.

        CheckFieldOnSalesTable(DATABASE::"Sales Invoice Line", ServiceItemLineNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServPriceAdjmtGrCodeOnInvLine()
    begin
        // Covers document number TC-PP-RS-6 - refer to TFS ID 20926.
        // Test that Serv. Price Adjmt. Gr. Code Field is removed from the Sales Invoice Line.

        CheckFieldOnSalesTable(DATABASE::"Sales Invoice Line", ServPriceAdjmtGrCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceContactNoOnCrMemoLine()
    begin
        // Covers document number TC-PP-RS-7 - refer to TFS ID 20926.
        // Test that Service Contract No. Field is removed from the Sales Cr.Memo Line.

        CheckFieldOnSalesTable(DATABASE::"Sales Cr.Memo Line", ServiceContractNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderNoOnCrMemoLine()
    begin
        // Covers document number TC-PP-RS-7 - refer to TFS ID 20926.
        // Test that Service Order No. Field is removed from the Sales Cr.Memo Line.

        CheckFieldOnSalesTable(DATABASE::"Sales Cr.Memo Line", ServiceOrderNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceItemNoOnCrMemoLine()
    begin
        // Covers document number TC-PP-RS-7 - refer to TFS ID 20926.
        // Test that Service Item No. Field is removed from the Sales Cr.Memo Line.

        CheckFieldOnSalesTable(DATABASE::"Sales Cr.Memo Line", ServiceItemNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AppltoServiceEntryOnCrMemoLine()
    begin
        // Covers document number TC-PP-RS-7 - refer to TFS ID 20926.
        // Test that Appl.-to Service Entry Field is removed from the Sales Cr.Memo Line.

        CheckFieldOnSalesTable(DATABASE::"Sales Cr.Memo Line", AppltoServiceEntry);
    end;

    local procedure CheckFieldOnSalesTable(TableNo: Integer; FieldName: Text[30])
    var
        LibraryUtility: Codeunit "Library - Utility";
        FieldExist: Boolean;
    begin
        // 1. Setup:
        Initialize();
        // 2. Exercise: Set the filters on Field table for the Table No and Field Name.
        FieldExist := LibraryUtility.CheckFieldExistenceInTable(TableNo, FieldName);

        // 3. Verify: Check that the Service related field is removed from the Sales Related Table.
        Assert.IsFalse(FieldExist, StrSubstNo(FieldMustNotExistError, FieldName));
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Service Removal From Sales");
        if Initialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Service Removal From Sales");
        Initialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Service Removal From Sales");
    end;
}

