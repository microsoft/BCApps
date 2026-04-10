#pragma warning disable AA0247
xmlport 17202 "Norm Jurisdiction"
{
    Caption = 'Norm Jurisdiction';

    schema
    {
        textelement(NormJurisdictionSetup)
        {
            tableelement("Tax Register Norm Jurisdiction"; "Tax Register Norm Jurisdiction")
            {
                MinOccurs = Zero;
                XmlName = 'NormJurisdiction';
                UseTemporary = true;
                fieldelement(Code; "Tax Register Norm Jurisdiction".Code)
                {
                }
                fieldelement(Description; "Tax Register Norm Jurisdiction".Description)
                {
                }
                tableelement("Tax Register Norm Group"; "Tax Register Norm Group")
                {
                    LinkFields = "Norm Jurisdiction Code" = field(Code);
                    LinkTable = "Tax Register Norm Jurisdiction";
                    MinOccurs = Zero;
                    XmlName = 'NormGroup';
                    UseTemporary = true;
                    fieldelement(NormJurisdictionCode; "Tax Register Norm Group"."Norm Jurisdiction Code")
                    {
                    }
                    fieldelement(Code; "Tax Register Norm Group".Code)
                    {
                    }
                    fieldelement(Description; "Tax Register Norm Group".Description)
                    {
                    }
                    fieldelement(SearchDetail; "Tax Register Norm Group"."Search Detail")
                    {
                    }
                    fieldelement(StoringMethod; "Tax Register Norm Group"."Storing Method")
                    {
                    }
                    fieldelement(Check; "Tax Register Norm Group".Check)
                    {
                    }
                    fieldelement(Level; "Tax Register Norm Group".Level)
                    {
                    }
                    tableelement("Tax Register Norm Detail"; "Tax Register Norm Detail")
                    {
                        LinkFields = "Norm Jurisdiction Code" = field("Norm Jurisdiction Code"), "Norm Group Code" = field(Code);
                        LinkTable = "Tax Register Norm Group";
                        MinOccurs = Zero;
                        XmlName = 'NormDetail';
                        UseTemporary = true;
                        fieldelement(NormJurisdictionCode; "Tax Register Norm Detail"."Norm Jurisdiction Code")
                        {
                        }
                        fieldelement(NormGroupCode; "Tax Register Norm Detail"."Norm Group Code")
                        {
                        }
                        fieldelement(NormType; "Tax Register Norm Detail"."Norm Type")
                        {
                        }
                        fieldelement(EffectiveDate; "Tax Register Norm Detail"."Effective Date")
                        {
                        }
                        fieldelement(Maximum; "Tax Register Norm Detail".Maximum)
                        {
                        }
                        fieldelement(Norm; "Tax Register Norm Detail".Norm)
                        {
                        }
                        fieldelement(NormAboveMaximum; "Tax Register Norm Detail"."Norm Above Maximum")
                        {
                        }
                    }
                }
            }
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    var
        NormGroup: Record "Tax Register Norm Group";
        NormDetail: Record "Tax Register Norm Detail";

    [Scope('OnPrem')]
    procedure SetData(var NormJurisdiction: Record "Tax Register Norm Jurisdiction")
    begin
        if NormJurisdiction.FindSet() then
            repeat
                "Tax Register Norm Jurisdiction" := NormJurisdiction;
                "Tax Register Norm Jurisdiction".Insert();

                NormGroup.SetRange("Norm Jurisdiction Code", NormJurisdiction.Code);
                if NormGroup.FindSet() then
                    repeat
                        "Tax Register Norm Group" := NormGroup;
                        "Tax Register Norm Group".Insert();

                        NormDetail.SetRange("Norm Jurisdiction Code", NormJurisdiction.Code);
                        NormDetail.SetRange("Norm Group Code", NormGroup.Code);
                        if NormDetail.FindSet() then
                            repeat
                                "Tax Register Norm Detail" := NormDetail;
                                "Tax Register Norm Detail".Insert();
                            until NormDetail.Next() = 0;
                    until NormGroup.Next() = 0;
            until NormJurisdiction.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure ImportData()
    var
        NormJurisdiction: Record "Tax Register Norm Jurisdiction";
    begin
        "Tax Register Norm Jurisdiction".Reset();
        if "Tax Register Norm Jurisdiction".FindSet() then
            repeat
                NormJurisdiction := "Tax Register Norm Jurisdiction";
                if NormJurisdiction.Find() then begin
                    NormJurisdiction.Delete(true);
                    NormJurisdiction := "Tax Register Norm Jurisdiction";
                end;
                NormJurisdiction.Insert();
            until "Tax Register Norm Jurisdiction".Next() = 0;

        "Tax Register Norm Group".Reset();
        if "Tax Register Norm Group".FindSet() then
            repeat
                NormGroup := "Tax Register Norm Group";
                if NormGroup.Find() then begin
                    NormGroup.Delete(true);
                    NormGroup := "Tax Register Norm Group";
                end;
                NormGroup.Insert();
            until "Tax Register Norm Group".Next() = 0;

        "Tax Register Norm Detail".Reset();
        if "Tax Register Norm Detail".FindSet() then
            repeat
                NormDetail := "Tax Register Norm Detail";
                if NormDetail.Find() then begin
                    NormDetail.Delete(true);
                    NormDetail := "Tax Register Norm Detail";
                end;
                NormDetail.Insert();
            until "Tax Register Norm Detail".Next() = 0;
    end;
}

