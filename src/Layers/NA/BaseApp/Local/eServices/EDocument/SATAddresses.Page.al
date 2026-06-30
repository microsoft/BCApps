// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

page 27009 "SAT Addresses"
{
    ApplicationArea = BasicMX;
    PageType = List;
    SourceTable = "SAT Address";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Id; Rec.Id)
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the Id of the address where the domicile of the origin or destination of the goods or merchandise that are moved in the different means of transport is located.';
                    Visible = false;
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the country/region of the address where the domicile of the origin or destination of the goods or merchandise that are moved in the different means of transport is located.';
                }
                field("SAT State Code"; Rec."SAT State Code")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the state, entity, region, community, or similar definitions where the domicile of the origin and / or destination of the goods or merchandise that are moved in the different means of transport is located.';
                }
                field("SAT Municipality Code"; Rec."SAT Municipality Code")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the municipality, delegation or mayoralty, county, or similar definitions where the destination address of the goods or merchandise that are moved in the different means of transport is located.';
                }
                field("SAT Locality Code"; Rec."SAT Locality Code")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the city, town, district, or similar definition where the domicile of origin and / or destination of the goods or merchandise that are moved in the different means of transport is located.';
                }
                field("SAT Suburb Code"; SATSuburb."Suburb Code")
                {
                    ApplicationArea = BasicMX;
                    Caption = 'SAT Suburb Code';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the SAT suburb code where the domicile of the origin or destination of the goods or merchandise that are moved in the different means of transport is located.';

                    trigger OnAssistEdit()
                    var
                        SATSuburbList: Page "SAT Suburb List";
                    begin
                        SATSuburbList.SetRecord(SATSuburb);
                        SATSuburbList.LookupMode := true;
                        if SATSuburbList.RunModal() = ACTION::LookupOK then begin
                            SATSuburbList.GetRecord(SATSuburb);
                            Rec."SAT Suburb ID" := SATSuburb.ID;
                            if Rec.Modify() then;
                        end;
                    end;
                }
                field("SAT Postal Code"; SATSuburb."Postal Code")
                {
                    ApplicationArea = BasicMX;
                    Caption = 'SAT Postal Code';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the SAT postal code where the domicile of the origin or destination of the goods or merchandise that are moved in the different means of transport is located.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        Clear(SATSuburb);
        if SATSuburb.Get(Rec."SAT Suburb ID") then;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Clear(SATSuburb);
    end;

    var
        SATSuburb: Record "SAT Suburb";
}

