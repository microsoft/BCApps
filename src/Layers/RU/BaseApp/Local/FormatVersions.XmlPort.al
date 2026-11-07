#pragma warning disable AA0247
xmlport 26551 "Format Versions"
{
    Caption = 'Format Versions';

    schema
    {
        textelement(FormatVersions)
        {
            tableelement("format version"; "Format Version")
            {
                MinOccurs = Zero;
                XmlName = 'FormatVersion';
                UseTemporary = true;
                fieldelement(FormatVersionCode; "Format Version".Code)
                {
                }
                fieldelement(KNDCode; "Format Version"."KND Code")
                {
                }
                fieldelement(ReportDescription; "Format Version"."Report Description")
                {
                }
                fieldelement(PartNo; "Format Version"."Part No.")
                {
                }
                fieldelement(VerisionNo; "Format Version"."Version No.")
                {
                }
                fieldelement(ReportType; "Format Version"."Report Type")
                {
                }
                fieldelement(UsageStartingDate; "Format Version"."Usage Starting Date")
                {
                }
                fieldelement(UsageFirstReportingPeriod; "Format Version"."Usage First Reporting Period")
                {
                }
                fieldelement(UsageEndingDate; "Format Version"."Usage Ending Date")
                {
                }
                fieldelement(RegisterNo; "Format Version"."Register No.")
                {
                }
                fieldelement(ExcelFileName; "Format Version"."Excel File Name")
                {
                }
                fieldelement(XMLSchemaFileName; "Format Version"."XML Schema File Name")
                {
                }
                fieldelement(FormOrderNoApprDate; "Format Version"."Form Order No. & Appr. Date")
                {
                }
                fieldelement(FormatOrderNoApprDate; "Format Version"."Format Order No. & Appr. Date")
                {
                }
                fieldelement(Comment; "Format Version".Comment)
                {
                }
                fieldelement(XMLFileNameElementName; "Format Version"."XML File Name Element Name")
                {
                    MinOccurs = Zero;
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
        FormatVersion: Record "Format Version";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label '%1 cannot be imported because there are linked reports.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    [Scope('OnPrem')]
    procedure SetData(var TempFormatVersion: Record "Format Version")
    begin
        if TempFormatVersion.FindSet() then
            repeat
                "Format Version" := TempFormatVersion;
                "Format Version".Insert();
            until TempFormatVersion.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure ImportData(PathName: Text[1024])
    begin
        "Format Version".Reset();
        if "Format Version".FindSet() then
            repeat
                if FormatVersion.Get("Format Version".Code) then
                    FormatVersion.Delete(true);
                FormatVersion := "Format Version";

                if FormatVersion.HasLinkedReports() then
                    Error(Text001, FormatVersion.GetRecDescription());

                if FormatVersion."Excel File Name" <> '' then
                    FormatVersion.ImportExcelTemplate(PathName + FormatVersion."Excel File Name");
                if FormatVersion."XML Schema File Name" <> '' then
                    FormatVersion.ImportXMLSchema(PathName + FormatVersion."XML Schema File Name");
                FormatVersion.Insert();
            until "Format Version".Next() = 0;
    end;
}

