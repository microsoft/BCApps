// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Picture;

table 7499 "Item From Picture Buffer"
{
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; PrimaryKey; Integer)
        {
            AutoIncrement = true;
        }
        field(10; ItemMediaSet; MediaSet)
        {
        }
        field(11; ItemMediaFileName; Text[260])
        {
        }
        field(20; ItemTemplateCode; Code[20])
        {
        }
        field(25; ItemCategoryCode; Code[20])
        {
        }
        field(30; ItemDescription; Text[100])
        {
        }
        field(100; AnalysisResult; Blob)
        {
        }
        field(101; AnalysisResultPreview; Text[2048])
        {
        }
    }

    keys
    {
        key(PK; PrimaryKey)
        {
            Clustered = true;
        }
    }

    procedure SetResult(Result: Text)
    var
        ResultOutStream: OutStream;
    begin
        Clear(Rec.AnalysisResult);
        Rec.AnalysisResult.CreateOutStream(ResultOutStream);
        ResultOutStream.WriteText(Result);

        Rec.Validate(AnalysisResultPreview, CopyStr(Result, 1, MaxStrLen(Rec.AnalysisResultPreview)));
    end;
}
