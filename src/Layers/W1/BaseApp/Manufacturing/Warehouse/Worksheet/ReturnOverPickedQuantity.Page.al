// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Worksheet;

using Microsoft.Warehouse.Structure;
using Microsoft.Inventory.Location;

page 8370 "Return Overpicked Quantity"
{
    PageType = StandardDialog;
    InsertAllowed = false;
    DeleteAllowed = false;
    Caption = 'Return Overpicked Quantity';

    layout
    {
        area(Content)
        {
            group(Input)
            {
                field(WorksheetTemplName; WorksheetTemplName)
                {
                    Caption = 'Worksheet Template Name';
                    ApplicationArea = Manufacturing;
                    Editable = false;
                }
                field(WorksheetName; WorksheetName)
                {
                    Caption = 'Worksheet Name';
                    ApplicationArea = Manufacturing;
                    Editable = false;
                }
                field(LocationCode; LocationCode)
                {
                    Caption = 'Location Code';
                    ApplicationArea = Manufacturing;
                    Editable = false;
                }
                field(FromBinCode; FromBinCode)
                {
                    Caption = 'From Bin Code';
                    ApplicationArea = Manufacturing;
                    TableRelation = Bin.Code;
                    Editable = false;
                }
                field(ToBinCode; ToBinCode)
                {
                    Caption = 'To Bin Code';
                    ApplicationArea = Manufacturing;
                    Lookup = true;

                    trigger OnValidate()
                    var
                        Bin: Record Bin;
                    begin
                        ToZoneCode := '';
                        if ToBinCode <> '' then begin
                            Bin.Get(LocationCode, ToBinCode);
                            ToZoneCode := Bin."Zone Code";
                        end;

                        CurrPage.Update(true);
                    end;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Bin: Record Bin;
                    begin
                        Bin.SetRange("Location Code", LocationCode);
                        if Page.RunModal(0, Bin) = Action::LookupOK then begin
                            ToBinCode := Bin.Code;
                            ToZoneCode := Bin."Zone Code";
                        end;

                        CurrPage.Update(true);
                    end;
                }
                field(ToZoneCode; ToZoneCode)
                {
                    Caption = 'To Zone Code';
                    ApplicationArea = Manufacturing;
                    TableRelation = Zone.Code;

                    trigger OnValidate()
                    begin
                        ToBinCode := '';
                    end;
                }
            }
        }
    }

    var
        Location: Record Location;
        CreateProdMovementWksht: Codeunit "Create Prod. Movement Wksht.";
        WorksheetName: Text;
        WorksheetTemplName: Code[10];
        LocationCode: Code[10];
        FromBinCode: Code[20];
        ToBinCode: Code[20];
        ToZoneCode: Code[20];

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [Action::LookupOK, Action::OK, Action::Yes] then begin
            CreateProdMovementWksht.SetContext(WorksheetTemplName, WorksheetName, LocationCode, FromBinCode, ToBinCode, ToZoneCode);
            CreateProdMovementWksht.StartMovement();
        end;
    end;

    procedure SetContext(NewWorksheetTemplName: Code[10]; NewWorksheetName: Text; NewLocationCode: Code[10])
    begin
        WorksheetTemplName := NewWorksheetTemplName;
        WorksheetName := NewWorksheetName;
        LocationCode := NewLocationCode;

        Location.Get(LocationCode);
        FromBinCode := Location."To-Production Bin Code";
    end;
}
