// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Document;

report 5884 "Calc. Phys. Invt. Order Count"
{
    Caption = 'Calc. Phys. Invt. Order Count';
    ProcessingOnly = true;

    dataset
    {
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(CalcQtyExpected; CalcQtyExpectedReq)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Calculate Qty. Expected';
                        ToolTip = 'Specifies if you want the program to calculate and insert the contents of the field quantity expected for new created physical inventory order lines.';
                    }
                    field(ZeroQty; ZeroQtyReq)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Items Not on Inventory';
                        ToolTip = 'Specifies if physical inventory order lines should be created for items that are not on inventory, that is, items where the value in the Qty. Expected (Base) field is 0.';

                        trigger OnValidate()
                        begin
                            if not ZeroQtyReq then
                                IncludeItemWithNoTransaction := false;
                        end;
                    }
                    field(IncludeItemWithNoTransactionField; IncludeItemWithNoTransaction)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include Items without Transactions';
                        ToolTip = 'Specifies if physical inventory order lines should be created for items that are not on inventory and are not used in any transactions.';

                        trigger OnValidate()
                        begin
                            if IncludeItemWithNoTransaction then
                                ZeroQtyReq := true;
                        end;
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        OKPressed := true;
    end;

    protected var
        ZeroQtyReq: Boolean;
        CalcQtyExpectedReq: Boolean;
        IncludeItemWithNoTransaction: Boolean;
        OKPressed: Boolean;

    procedure GetRequest(var ZeroQty2: Boolean; var CalcQtyExpected2: Boolean): Boolean
    var
        DummyIncludeItemWithNoTransaction: Boolean;
    begin
        exit(GetRequest(ZeroQty2, CalcQtyExpected2, DummyIncludeItemWithNoTransaction));
    end;

    procedure GetRequest(var ZeroQty2: Boolean; var CalcQtyExpected2: Boolean; var IncludeItemWithNoTransaction2: Boolean): Boolean
    begin
        ZeroQty2 := ZeroQtyReq;
        CalcQtyExpected2 := CalcQtyExpectedReq;
        IncludeItemWithNoTransaction2 := IncludeItemWithNoTransaction;
        exit(OKPressed);
    end;
}

