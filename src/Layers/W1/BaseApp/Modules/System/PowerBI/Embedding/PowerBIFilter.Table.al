namespace System.Integration.PowerBI;

table 6315 "Power BI Filter"
{
    Access = Internal;
    TableType = Temporary;

    fields
    {
        field(1; PrimaryKey; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(2; FilterOperator; Enum "Power BI Filter Operator")
        {
            DataClassification = SystemMetadata;
        }
        field(3; FilterValuesJson; Blob)
        {
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; PrimaryKey)
        {
            Clustered = true;
        }
    }

    procedure ReadFilterValues() FilterValues: JsonArray
    var
        FilterInStream: InStream;
        FilterValuesText: Text;
    begin
        Rec.CalcFields(FilterValuesJson);
        if not Rec.FilterValuesJson.HasValue() then
            exit;

        Rec.FilterValuesJson.CreateInStream(FilterInStream);
        FilterInStream.ReadText(FilterValuesText);

        if FilterValuesText = '' then
            exit;

        FilterValues.ReadFrom(FilterValuesText);
    end;

    procedure OverwriteFilterValues(FilterValues: JsonArray)
    var
        FilterOutStream: OutStream;
        FilterValuesText: Text;
    begin
        FilterValues.WriteTo(FilterValuesText);

        Clear(Rec.FilterValuesJson);
        Rec.FilterValuesJson.CreateOutStream(FilterOutStream);

        FilterOutStream.WriteText(FilterValuesText);
    end;
}