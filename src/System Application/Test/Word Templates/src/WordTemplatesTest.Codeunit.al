// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Integration.Word;

using System.Integration.Word;
using System.Text;
using System.Utilities;
using System.TestLibraries.Integration.Word;
using System.TestLibraries.Utilities;
using System.TestLibraries.Security.AccessControl;

/// <summary>
/// Tests for Mail Merge codeunit
/// </summary>
codeunit 130443 "Word Templates Test"
{
    Subtype = Test;

    var
        PermissionsMock: Codeunit "Permissions Mock";
        Assert: Codeunit "Library Assert";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AddUnrelatedTableCreatesRecord()
    var
        WordTemplatesRelatedTable: Record "Word Templates Related Table";
        Any: Codeunit Any;
        WordTemplate: Codeunit "Word Template";
        PrefixCode: Code[5];
        TemplateCode: Code[30];
        RelatedTableSystemId: Guid;
    begin
        // [SCENARIO 3105] Calling AddUnrelatedTable creates a related table record correctly

        // [GIVEN] A Word Template Code
        TemplateCode := CopyStr(Any.AlphabeticText(10), 1, MaxStrLen(TemplateCode));

        // [GIVEN] A prefix code for the unrelated table
        PrefixCode := CopyStr(Any.AlphabeticText(5), 1, MaxStrLen(PrefixCode));

        // [GIVEN] A SystemId for the unrelated table record
        RelatedTableSystemId := CreateGuid();

        // [WHEN] AddUnrelatedTable is called for a specific table and record
        WordTemplate.AddUnrelatedTable(TemplateCode, PrefixCode, Database::"Word Templates Table", RelatedTableSystemId);

        // [THEN] The related table record is created
        WordTemplatesRelatedTable.Get(TemplateCode, Database::"Word Templates Table");

        // [THEN] The values match the provided parameters
        Assert.AreEqual(PrefixCode, WordTemplatesRelatedTable."Related Table Code", WordTemplatesRelatedTable.FieldName("Related Table Code"));
        Assert.AreEqual(RelatedTableSystemId, WordTemplatesRelatedTable."Source Record ID", WordTemplatesRelatedTable.FieldName("Source Record ID"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AddUnrelatedTableReturnsTrueIfCreated()
    var
        WordTemplatesRelatedTable: Record "Word Templates Related Table";
        Any: Codeunit Any;
        WordTemplate: Codeunit "Word Template";
        Result: Boolean;
        PrefixCode: Code[5];
        TemplateCode: Code[30];
    begin
        // [SCENARIO 3105] Calling AddUnrelatedTable returns true if the record is created

        // [GIVEN] No related table records exist
        if not WordTemplatesRelatedTable.IsEmpty() then
            WordTemplatesRelatedTable.DeleteAll(false);

        // [WHEN] AddUnrelatedTable is called with arbitrary table and record id
        TemplateCode := CopyStr(Any.AlphabeticText(10), 1, MaxStrLen(TemplateCode));
        PrefixCode := CopyStr(Any.AlphabeticText(5), 1, MaxStrLen(PrefixCode));
        Result := WordTemplate.AddUnrelatedTable(TemplateCode, PrefixCode, Any.IntegerInRange(1, 100), CreateGuid());

        // [THEN] The method result is true
        Assert.IsTrue(Result, 'Unexpected method return value.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AddUnrelatedTableReturnsFalseIfNotCreated()
    var
        Any: Codeunit Any;
        WordTemplate: Codeunit "Word Template";
        Result: Boolean;
        PrefixCode: Code[5];
        TemplateCode: Code[30];
        RelatedTableSystemId: Guid;
    begin
        // [SCENARIO 3105] Calling AddUnrelatedTable returns false if related table already exists

        // [GIVEN] A Word Template Code
        TemplateCode := CopyStr(Any.AlphabeticText(10), 1, MaxStrLen(TemplateCode));

        // [GIVEN] A prefix code for the unrelated table
        PrefixCode := CopyStr(Any.AlphabeticText(5), 1, MaxStrLen(PrefixCode));

        // [GIVEN] A SystemId for the unrelated table record
        RelatedTableSystemId := CreateGuid();

        // [GIVEN] The related table already exists
        WordTemplate.AddUnrelatedTable(TemplateCode, PrefixCode, Database::"Word Templates Table", RelatedTableSystemId);

        // [WHEN] AddUnrelatedTable is called for the same table and record
        Result := WordTemplate.AddUnrelatedTable(TemplateCode, PrefixCode, Database::"Word Templates Table", RelatedTableSystemId);

        // [THEN] The user is informed that the (un)related table already exists
        // Verified by MessageHandler

        // [THEN] The method result is false
        Assert.IsFalse(Result, 'Unexpected method return value.');
    end;

    [Test]
    procedure TestCreateDocument()
    var
        WordTemplates: Codeunit "Word Template";
        MergeFields: List of [Text];
        InStream: InStream;
    begin
        // [SCENARIO] Creation of document template with fields provides zip with document template and data source txt file
        PermissionsMock.Set('Word Templates Edit');

        // [GIVEN] Merge fields
        MergeFields.Add('CustomerName');
        MergeFields.Add('Address');

        // [WHEN] Run create document with merge fields and save zip to temp blob
        WordTemplates.Create(MergeFields);

        // [THEN] Open zip to verify contents
        WordTemplates.GetTemplate(InStream);

        Assert.IsFalse(InStream.EOS(), 'The Template should not have been empty.');
    end;

    [Test]
    procedure TestCreateDocumentInternals()
    var
        WordTemplatesImpl: Codeunit "Word Template Impl.";
        MergeFields: List of [Text];
    begin
        // [SCENARIO] Creation of document template with fields provides zip with document template and data source txt file
        PermissionsMock.Set('Word Templates Edit');

        // [GIVEN] Merge fields
        MergeFields.Add('CustomerName');
        MergeFields.Add('Address');

        // [WHEN] Run create document with merge fields and save zip to temp blob
        WordTemplatesImpl.Create(MergeFields);

        // [THEN] Verify the Merge fields are set correctly
        WordTemplatesImpl.GetMergeFields(MergeFields);

        Assert.IsTrue(MergeFields.Contains('CustomerName'), 'CustomerName should have been part of the Merge Fields.');
        Assert.IsTrue(MergeFields.Contains('Address'), 'Address should have been part of the Merge Fields.');
    end;

    [Test]
    procedure TestCreateDocumentInternalsForRecord()
    var
        TempWordTemplateFields: Record "Word Template Field" temporary;
        WordTemplatesImpl: Codeunit "Word Template Impl.";
        MergeFields: List of [Text];
    begin
        // [SCENARIO] Creation of document template with fields provides zip with document template and data source txt file
        PermissionsMock.Set('Word Templates Edit');

        // [WHEN] Run create document with merge fields and save zip to temp blob
        WordTemplatesImpl.Create(Database::"Word Template", TempWordTemplateFields);

        // [THEN] Verify the Merge fields are set correctly
        WordTemplatesImpl.GetMergeFields(MergeFields);

        Assert.IsTrue(MergeFields.Contains('Code'), 'Code should have been part of the Merge Fields.');
        Assert.IsTrue(MergeFields.Contains('Name'), 'Name should have been part of the Merge Fields.');
        Assert.IsTrue(MergeFields.Contains('Table ID'), 'Table ID should have been part of the Merge Fields.');
        Assert.IsTrue(MergeFields.Contains('Table Caption'), 'Table Caption should have been part of the Merge Fields.');
        Assert.IsTrue(MergeFields.Contains('System ID'), 'System Id should have been part of the Merge Fields.');
        Assert.IsTrue(MergeFields.Contains('Created At'), 'Created At should have been part of the Merge Fields.');
        Assert.IsTrue(MergeFields.Contains('Created By'), 'Created By should have been part of the Merge Fields.');
        Assert.IsTrue(MergeFields.Contains('Modified At'), 'Modified At should have been part of the Merge Fields.');
        Assert.IsTrue(MergeFields.Contains('Modified By'), 'Modified By should have been part of the Merge Fields.');

        // [THEN] Verify the TableNo of the Template is set correctly
        Assert.AreEqual(Database::"Word Template", WordTemplatesImpl.GetTableId(), 'A different table ID was expected.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('ConfirmHandlerFalse')]
    procedure TestLoadDocumentAndExecute()
    var
        WordTemplateRec: Record "Word Template";
        Base64: Codeunit "Base64 Convert";
        Document: Codeunit "Temp Blob";
        DataSource: Codeunit "Temp Blob";
        WordTemplate: Codeunit "Word Template";
        WordTemplateCode: Code[30];
        OutputText: Text;
        OutStream: OutStream;
        InStream: InStream;
        CR, CL : Char;
    begin
        // [SCENARIO] Load document and execute upon a dataset and verify that the output contains the data

        // [GIVEN] Document from base64 and two records. Records contains multiline values and special characters.
        PermissionsMock.Stop();
        CR := 13;
        CL := 10;
        InsertWordTemplatesTestTable(1, 'Value' + CR + CL + '1', 'Value2', 'Value3');
        InsertWordTemplatesTestTable(2, 'Value4', 'Value5', 'Valüe6');

        Document.CreateOutStream(OutStream, TextEncoding::UTF8);
        Base64.FromBase64(GetTemplateDocumentForRecord(), OutStream);
        Document.CreateInStream(InStream, TextEncoding::UTF8);

        WordTemplateCode := 'TEST';
        WordTemplateRec.Code := WordTemplateCode;
        WordTemplateRec."Table ID" := Database::"Word Templates Test Table 2";
        WordTemplateRec.Template.ImportStream(InStream, 'Template');
        WordTemplateRec.Insert();

        PermissionsMock.Start();
        PermissionsMock.Set('Word Templates Edit');

        // [WHEN] Load document from stream and execute upon with datasource
        WordTemplate.Load(WordTemplateCode);
        DataSource.CreateInStream(InStream, TextEncoding::UTF8);
        WordTemplate.Merge(false, Enum::"Word Templates Save Format"::Text);

        // [THEN] Check document for data source values
        WordTemplate.GetDocument(InStream);
        InStream.Read(OutputText);

        Assert.IsTrue(OutputText.Contains('Value' + CR + CL + '1'), 'Value \n 1 is missing from the document');
        Assert.IsTrue(OutputText.Contains('Value2'), 'Value2 is missing from the document');
        Assert.IsTrue(OutputText.Contains('Value3'), 'Value3 is missing from the document');
        Assert.IsTrue(OutputText.Contains('Value4'), 'Value4 is missing from the document');
        Assert.IsTrue(OutputText.Contains('Value5'), 'Value5 is missing from the document');
        Assert.IsTrue(OutputText.Contains('Valüe6'), 'Valüe6 is missing from the document');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestLoadDocumentAndExecuteDictionary()
    var
        WordTemplateRec: Record "Word Template";
        Base64: Codeunit "Base64 Convert";
        Document: Codeunit "Temp Blob";
        WordTemplates: Codeunit "Word Template";
        DataSource: Dictionary of [Text, Text];
        OutputText: Text;
        OutStream: OutStream;
        InStream: InStream;
    begin
        // [SCENARIO] Load document and execute upon a dataset and verify that the output contains the data
        PermissionsMock.Set('Word Templates Edit');

        // [GIVEN] Document from base64 and data source
        DataSource.Add('CustomerName', 'Darrick');
        DataSource.Add('Address', 'Copenhagen');
        DataSource.Add('TæstChår', 'FTæst');

        Document.CreateOutStream(OutStream, TextEncoding::UTF8);
        Base64.FromBase64(GetTemplateDocument(), OutStream);
        Document.CreateInStream(InStream, TextEncoding::UTF8);

        WordTemplateRec.Code := 'TEST';
        WordTemplateRec.Template.ImportStream(InStream, 'Template');
        WordTemplateRec.Insert();

        WordTemplates.Load(WordTemplateRec.Code);
        WordTemplates.Merge(DataSource, Enum::"Word Templates Save Format"::Text);

        // [THEN] Check document for data source values
        WordTemplates.GetDocument(InStream);
        InStream.Read(OutputText);

        Assert.IsTrue(WordTemplates.GetDocumentSize() > 0, 'Document do not have a size');
        Assert.IsTrue(OutputText.Contains('Darrick'), 'Darrick is missing from the document');
        Assert.IsTrue(OutputText.Contains('Copenhagen'), 'Copenhagen is missing from the document');
        Assert.IsTrue(OutputText.Contains('FTæst'), 'FTæst is missing from the document');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestGetTemplateName()
    var
        TempWordTemplateFields: Record "Word Template Field" temporary;
        WordTemplateImpl: Codeunit "Word Template Impl.";
    begin
        // [SCENARIO] Check that reserved characters are removed from the template name.
        PermissionsMock.Set('Word Templates Edit');
        WordTemplateImpl.Create(130443, TempWordTemplateFields); // Caption = Word Templates Test / Table "<>:/\|?*
        Assert.AreEqual('Word Templates Test _ Table __________Template.docx', WordTemplateImpl.GetTemplateName('docx'), 'Template name is incorrect.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestGenerateColumnName()
    var
        WordTemplateImpl: Codeunit "Word Template Impl.";
    begin
        // [SCENARIO] Check conversion of column numbers to column names for excel column
        PermissionsMock.Set('Word Templates Edit');

        Assert.AreEqual('', WordTemplateImpl.ConvertColNoToColName(0), 'Column name is incorrect.');
        Assert.AreEqual('A', WordTemplateImpl.ConvertColNoToColName(1), 'Column name is incorrect.');
        Assert.AreEqual('Z', WordTemplateImpl.ConvertColNoToColName(26), 'Column name is incorrect.');
        Assert.AreEqual('AA', WordTemplateImpl.ConvertColNoToColName(27), 'Column name is incorrect.');
        Assert.AreEqual('AC', WordTemplateImpl.ConvertColNoToColName(29), 'Column name is incorrect.');
        Assert.AreEqual('AZ', WordTemplateImpl.ConvertColNoToColName(52), 'Column name is incorrect.');
        Assert.AreEqual('ZZ', WordTemplateImpl.ConvertColNoToColName(702), 'Column name is incorrect.');
    end;

    local procedure InsertWordTemplatesTestTable(No: Integer; Value1: Text[100]; Value2: Text[100]; Value3: Text[100])
    var
        WordTemplatesTestTable2: Record "Word Templates Test Table 2";
    begin
        WordTemplatesTestTable2."No." := No;
        WordTemplatesTestTable2.Value := Value1;
        WordTemplatesTestTable2."Value 2" := Value2;
        WordTemplatesTestTable2."Value 3" := Value3;
        WordTemplatesTestTable2.Insert();
    end;

    local procedure GetTemplateDocument(): Text
    begin
        exit('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');
    end;

    local procedure GetTemplateDocumentForRecord(): Text
    begin
        exit('UEsDBBQABgAIAAAAIQCA0VzDeQEAAJIFAAATAAgCW0NvbnRlbnRfVHlwZXNdLnhtbCCiBAIooAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC0lMtqwzAQRfeF/oPRtsRKuiilxMmiDyj0BU0/YCKNE1NZEtLk9fcdx4kpJS+aZGOQZ+69Z2RL3f68NMkUQyyczUQnbYsErXK6sKNMfA2eWrciiQRWg3EWM7HAKPq9y4vuYOExJqy2MRNjIn8nZVRjLCGmzqPlSu5CCcTLMJIe1DeMUF632zdSOUtoqUWVh+h1HzCHiaHkcc6va5KAJorkvm6ssjIB3ptCAXFdTq3+k9JaJaSsXPbEceHjFTcIuTGhqmwPWOneeWtCoTH5gEBvUHKXnLmgpXZqUrIy3W2zgdPleaGw0VduPjiFMfKelyZtKiUUds2/lSPSwmA8PUXtuz8eiVhwDoCV816EGQ4/z0bxy3wvSM65AxgaPD1GY70XgvgEYv3sHM2xtNkVyZ0fwfnIJzr8Y+z1ka3ULR7YY6Bi91/XJLL10fNhdRto1IdnvyKBBgL5AkM0zzZ3B0CU6+BUGeBPmq+KpvJoEuXyRu39AAAA//8DAFBLAwQUAAYACAAAACEA+5llRx8BAADgAgAACwAIAl9yZWxzLy5yZWxzIKIEAiigAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAKySwUoDMRCG74LvEHLvznYVEem2FxEWFETqA4zJ7Da4yYQkavv2ptKiK+3SQ4/5559/vhkyW6xtLz4pRMOultOilIKcYm1cV8vX5cPkVoqY0Gns2VEtNxTlYn55MXuhHlNuiivjo8gpLtZylZK/A4hqRRZjwZ5crrQcLKb8DB14VO/YEVRleQPhb4acDzJFo2sZGn0lxXLj6ZRsbluj6J7VhyWXDowAWidymvTEh9wfksnbiCWGjlItNavnLEdA74scLeEwUXU60fFtwVJCjQlBcaBxnq1jDGh6zhMNHb80Xxw06J08RnN9hMYaFThymwrFdjcmA1QllNU/BtVjjCYbfrQe36gf3uVpf7zHba1xLe+JYPAv598AAAD//wMAUEsDBBQABgAIAAAAIQC1EpjuhAMAACoOAAARAAAAd29yZC9kb2N1bWVudC54bWykl91uozgUx+9X2ndA3LfmM0lRk1E+q0o7o2g6u7eVCyagwRjZTpPuK+0j7N082R6br2TojoDeAPbx+fn8j+0D3H8608x4JVykLJ+b9q1lGiQPWZTmh7n557fdzcw0hMR5hDOWk7n5RoT5afH7b/enIGLhkZJcGoDIRXAqwrmZSFkECIkwIRSLW5qGnAkWy9uQUcTiOA0JOjEeIceyLf1UcBYSIWC+Nc5fsTArXHjuR4s4PoGzAnooTDCX5Nwy7MEQH92hWRfkjACBQsfuotzBqAlSUXVA3igQRNUh+eNI74ibjCM5XdJ0HMntkmbjSJ3tRLsbnBUkB2PMOMUSmvyAKObfj8UNgAss05c0S+UbMK1JjcFp/n1ERODVEKgbDSZMEWURydyoprC5eeR5UPnfNP4q9KD0r26NB8n6TQvT3SFylpmQtS/vk7vSfVMVFp01xEkGeWS5SNKiqQ50LA2MSQ15/VUCXmlWjzsVds+j9n+lbVMuQwvsE361djQrI/810bZ6rKZCNB59Qries46Ewg5uJx6Vmovk2j2LTw1wOoBJSHq+LGrGrGKgsD3dipP2PFY1p1wVxUnbxNo9a+DPwVwARCSjZBDFqfOKlC+WOMGi2eiKSIYF5Te4N3qRo+LwsYPwwNmxaGnpx2iPbUk8qY+TAazqQF0ecvGxYJ4SXEClpGHweMgZxy8ZRATHw4AdbugVUFfYKOqmH8lZ96u1NlSNMRfwVfXCojd1L8DmBQXm+BE2peu5G8ub+qbuhXeSVL22v9xMdzt4s5wC+IKLvs5Ny1pOpyt323RtSIyPmVQWz3fs5VbPEmfRU0qLDGIK0lxIqM7G5+3Xh+3ucfvHxvjCDD2M68te33K254zFaHGPmj65+PHPF/bjX9UlS4O+NnjdKt7Rs7adlbNeXevx197KndxZV3qqqD+k5y+cHUl/SXr4CFX+yl9a/u7uWpW7dHaTnbUZpqqy7IcJ/UaEfB6otvUZIdmbrT1rtfppY07c2cr2tq0+rcL2d+v3JV9ZRkt+dsaIfnZ6yRYklHv+jh6dk8PT32CCd6rtOJ7ev4k6njN4RuWAz1g5Swavftsrh/D0kMi2+cKkZLRtZyS+sCYERwSkTx3djBmTF83DUepmNV3IMgG9osAhKcfobvhje+CqAAVZmpN9KkOI0p1oK6ol6seyCqH2J2/xHwAAAP//AwBQSwMEFAAGAAgAAAAhANZks1H0AAAAMQMAABwACAF3b3JkL19yZWxzL2RvY3VtZW50LnhtbC5yZWxzIKIEASigAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAArJLLasMwEEX3hf6DmH0tO31QQuRsSiHb1v0ARR4/qCwJzfThv69ISevQYLrwcq6Yc8+ANtvPwYp3jNR7p6DIchDojK971yp4qR6v7kEQa1dr6x0qGJFgW15ebJ7Qak5L1PWBRKI4UtAxh7WUZDocNGU+oEsvjY+D5jTGVgZtXnWLcpXndzJOGVCeMMWuVhB39TWIagz4H7Zvmt7ggzdvAzo+UyE/cP+MzOk4SlgdW2QFkzBLRJDnRVZLitAfi2Myp1AsqsCjxanAYZ6rv12yntMu/rYfxu+wmHO4WdKh8Y4rvbcTj5/oKCFPPnr5BQAA//8DAFBLAwQUAAYACAAAACEAlrWt4vEFAABQGwAAFQAAAHdvcmQvdGhlbWUvdGhlbWUxLnhtbOxZS28TRxy/V+p3GO0d/IgdkggHxY4NLQSixFBxHO+OdwfP7qxmxgm+VXCsVKkqrXooUm89VG2RQOqFfpq0VC2V+Ar9z+x6vWOPwZBUpQIfvPP4/d+PnbEvXrobM3REhKQ8aXm181UPkcTnAU3Clnez3zu34SGpcBJgxhPS8iZEepe2P/zgIt5SEYkJAvpEbuGWFymVblUq0odlLM/zlCSwN+QixgqmIqwEAh8D35hV6tXqeiXGNPFQgmNge2M4pD5Bfc3S254y7zL4SpTUCz4Th5o1sSgMNhjV9ENOZIcJdIRZywM5AT/uk7vKQwxLBRstr2o+XmX7YqUgYmoJbYmuZz45XU4QjOqGToSDgrDWa2xe2C34GwBTi7hut9vp1gp+BoB9HyzNdCljG72NWnvKswTKhou8O9VmtWHjS/zXFvCb7Xa7uWnhDSgbNhbwG9X1xk7dwhtQNmwu6t/e6XTWLbwBZcP1BXzvwuZ6w8YbUMRoMlpA63gWkSkgQ86uOOEbAN+YJsAMVSllV0afqGW5FuM7XPQAYIKLFU2QmqRkiH3AdXA8EBRrAXiL4NJOtuTLhSUtC0lf0FS1vI9TDBUxg7x4+uOLp4/Ryb0nJ/d+Obl//+Tezw6qKzgJy1TPv//i74efor8ef/f8wVduvCzjf//ps99+/dINVGXgs68f/fHk0bNvPv/zhwcO+I7AgzK8T2Mi0XVyjA54DIY5BJCBeD2KfoRpmWInCSVOsKZxoLsqstDXJ5jl0bFwbWJ78JaAFuACXh7fsRQ+jMRYUQfwahRbwD3OWZsLp01XtayyF8ZJ6BYuxmXcAcZHLtmdufh2xynk8jQtbWhELDX3GYQchyQhCuk9PiLEQXabUsuve9QXXPKhQrcpamPqdEmfDqxsmhFdoTHEZeJSEOJt+WbvFmpz5mK/S45sJFQFZi6WhFluvIzHCsdOjXHMyshrWEUuJQ8nwrccLhVEOiSMo25ApHTR3BATS92rGHqRM+x7bBLbSKHoyIW8hjkvI3f5qBPhOHXqTJOojP1IjiBFMdrnyqkEtytEzyEOOFka7luUWOF+dW3fpKGl0ixB9M5Y5H3b6sAxTV7WjhmFfnzW7Rga4LNvH/6PGvEOvJNclTDffpfh5ptuh4uAvv09dxePk30Caf6+5b5vue9iy11Wz6s22llvNcfl6aHY8IuXnpCHlLFDNWHkmjRdWYLSQQ8WzcQQFQfyNIJhLs7ChQKbMRJcfUJVdBjhFMTUjIRQ5qxDiVIu4Rpglp289Qa8FVS21pxeAAGN1R4PsuW18sWwYGNmobl8TgWtaQarClu7cDphtQy4orSaUW1RWmGyU5p55N6EakBYX/tr6/VMNGQMZiTQfs8YTMNy5iGSEQ5IHiNt96IhNeO3FdymL3mrS9vUbE8hbZUglcU1loibRu80UZoymEVJ1+1cObLEnqFj0KpZb3rIx2nLG8IhCoZxCvykbkCYhUnL81VuyiuLed5gd1rWqksNtkSkQqpdLKOMymzlRCyZ6V9vNrQfzsYARzdaTYu1jdp/qIV5lENLhkPiqyUrs2m+x8eKiMMoOEYDNhYHGPTWqQr2BFTCO8Pkmp4IqFCzAzO78vMqmP99Jq8OzNII5z1Jl+jUwgxuxoUOZlZSr5jN6f6GppiSPyNTymn8jpmiMxeOrWuBHvpwDBAY6RxteVyoiEMXSiPq9wQcHIws0AtBWWiVENO/NmtdydGsb2U8TEHBOUQd0BAJCp1ORYKQfZXb+Qpmtbwr5pWRM8r7TKGuTLPngBwR1tfVu67t91A07Sa5IwxuPmj2PHfGINSF+raefLK0ed3jwUxQRr+qsFLTL70KNk+nwmu+arOOtSCu3lz5VZvC5QPpL2jcVPhsdr7t8wOIPmLTEyWCRDyXHTyQLsVsNACds8VMmmaVSfi3jlGzEBRy55xdLo4zdHZxXJpz9svFvbmz85Hl63IeOVxdWSzRSukiY2YL/zrxwR2QvQsXpTFT0thH7sJVszP9vwD4ZBIN6fY/AAAA//8DAFBLAwQUAAYACAAAACEAKfMyo5YHAADmGAAAEQAAAHdvcmQvc2V0dGluZ3MueG1s7Blrb+O48XuB/gfBKFqgqGNbsZ2sc96DnxffOYlrZ29bIECPlmibMEXqSMqPFv3vnSFFyVknRbKf8yWm5j3kzHCG+eHHQ8KDHVWaSdGtNC7qlYCKSMZMrLuVL4/j6nUl0IaImHApaLdypLry4+c//uGHfUdTY4BMByBC6E4SdSsbY9JOraajDU2IvpApFYBcSZUQA59qXUuI2mZpNZJJSgxbMs7MsRbW6+1KLkZ2K5kSnVxENWGRklquDLJ05GrFIpr/eA71Fr2OZSijLKHCWI01RTnYIIXesFR7acn3SgPkxgvZ/T8ndgn3dPtG/Q3u7qWKC463mIcMqZIR1RoOKOHeQCZKxc0zQYXuC9Cdu2hFAXujblenlrfeJyA8E9CO6OF9Mq5zGTXgPJXD4vfJaRdyWLmxjfb3GXMiQMcm3rxLSuj3tYa8xJAN0UUUoUT6PqNahbhjUu6R5m+JGoeasqUiyuVkHjJJ1JmshVRkycEcCJ0ATj+w1uFf2ET8sUt6sHDch8pnqBH/ljIJ9p2UqggSBQpMvV6pIQLCU64WhhgQ0dEp5dxWnIhTAhr3nbUiCdQKD7E82hw5nRFBx9bqMeOGKqDdEfDvclxvICPhfIF0GpThd5RpIxMPqiMIsh6MeQayovVEfMENt5ANJVgEn1GJLFlS9S3U4L48g8RM0cg4K7FEPoh5JrxB58gZUQT8TTevk9x7za9SPKIVhdOwaarE5lAj08vb525Z+I5p9q0LBPdWwEZZ6D1JHMaeA0QFv6NqTfMP4Qvh4zHF47TngUSgaEqWlGvHB9/bR/n3jEJ44TfG+ykLqGM76mgjKQR4uDDotCdwqN9RgActRtPR4DH4azCeP9wFvw1B5EJmEG1/+s1RoxIHCVQHC4WaxA2HIhHqm9MIUsbLy12EVIi2I6Wk0h6TM8lYS/zNYu4xMyV3LKaqe1ekZm8wuniYjob9i0Z4Ub+BsFLBZNjtxQkTN2hk4GzqDjpPiNRP2mwZ51Q8DeVecEli/fQV7XqkSYoBq2GlTWCPOQj/5cFPpccXB64PN3cypt05nPLN6ABhHtM4APsgAQ2DI/zz75k0N7fDefefo8XN5G70j27jxgFvfqYmsDZ3FkdtaBLg1i0JZIQjOCOb0zXTBs5iBlffa0QjsWaCBnjO3curEwQajtKDqYy2eMjW8voJxU9cLgkH6WA7/PYzvg0eUt0Nz2ks7lERofFQ4UoHt0qie7oPCnUzojUWydcMHiiKVSnfA8/WHROu6TO/InVMzesEQyn+YoKBTI/oIYFTkwI+oe+JzBlxDg++MrORmQnmNOUsIvhLmDojX4xn57AsTaVCjRAZUIfRsDOi/jEF9wMMuYlYyeBXwllsm6Az0ilLmIHoGfaDAYk2WEZekTbYSLiDxozy+EygSxpbIn26nORoXtdVVOZm6POfDylneHlYpk+5oJNy4cPTYVa3sXILtOOOpKjGVZ0iuamoflkgee2c7IPtg+2D7YPtg+2D7V1sNd8T1r7pjGO6Ihk30LEtoPP2gq7CvMUUcpaJyGT2svwFmm24YS0i2sA8EEH7vYCWAIADKYySRbcZy3tp8JJXMN47Ue41BVeZptg1wvAW2k7Rdu/zDPp6S7hWct/LjFwxY7+B/B6nBDcywcAwhYbOYqwWaBMm0EEK09PFAJK749l73PzChJbbbAptXh96p22pDmYxuUcv6MNqASOE1TJxo0qpBRsX9MWpsttRInNrYQ+g04RRg8Zu0HHyHfJRjpnSMA8eaPyVxWYzgHHSiWAauuTjLRHrjJd4iwMMM7O1NbknYhzC7ojalqp/hZ65x9laoDhszBbOa4u0bCdWwd5FuW0vSACfD8tDsWdCs/zAZ9DdOV8i6LFoPJC8TzgRkZPiDnbhHtogAARsIozEp49n2DXjwJYp9vanAjv1YTA1inbrJUVFNDUuobeOtn1pYJa+PaYbirOatJP6dyrOc6kMXaVZrP1iLqXxpPV67+qqfzlyliK2xDTC5nU/7w2fY5qN1njwIk+zFTZ6L2Je1zPohb1WK7c5tzTp4JPfTPnVGPI0SBzHgCRLxUhwh4+CNaRYqm2fCY9f0pVUtnP1mEW29Mhq1SE0JCYfw8Z7hK0ciY3qIV3ZNYeYXZdycwr1IhQK0s+FLHyPoeonJbPUYfeKpC4FPUmj2cw5mTAwDni4zpYLzyWIOp6gMhE/7JTdp3J7oG2HsKC4P1NSTvNFScX3CrXA0KFQVVMXgct1o1uB3NkY93bRwIZfbe3Hch3muNDiQoezHyRCz4A6X5Sw0MNO6C497LKENT2sWcJaHtYqYW0Pa9v3IphMFL5wQDL4JcJXEosgjW9L/BnIbYItGRMR8SymEA2xjKAk4hOZKxB6Q1I6dHcKRJ90gPyS0cGuQw8GNjVmphLolMUJOeB7W9hG6Tk11EKcLk9pEYfE6XMJMdxtPkufMdsM+MYWvOsihtfIMVmWN9WF84vDnbKAOVYRI4vnur9ZXKMJXkcTSDRY5an26WrQ6F07dKtAtxz6P1efPvVa/eZ1FTJ/XG2G/ctqr94eVdv1q0FvHPbC4fj6v3me+n9QfP4fAAAA//8DAFBLAwQUAAYACAAAACEAXIpdEQsBAACFAgAAHAAAAHdvcmQvX3JlbHMvc2V0dGluZ3MueG1sLnJlbHPckk9Lw0AQxe+C3yEseLSb5iBSuunBKPTQi6Z4Cci4O0mW7j92tpp+e1elYKGHnj3NDI/5Pd4wy9VkTfGBkbR3gs1nJSvQSa+0GwTbtk+396ygBE6B8Q4FOyCxVX19tXxGAykv0agDFZniSLAxpbDgnOSIFmjmA7qs9D5aSHmMAw8gdzAgr8ryjse/DFafMIu1EiyuVcWK9hDwErbvey2x8XJv0aUzFtyCNhuMA774fZSY0ZCHJFivDWY4f1h0W8rX6CjttDHousZ/OuNBUffqo7qpyhZtyEykn57Sd4F3g7lWb0exayDBr8lsMjQdnTZe5SiPU8LowDB+PvP8n2fmJ89TfwEAAP//AwBQSwMEFAAGAAgAAAAhAIQA0j8JCwAAAW4AAA8AAAB3b3JkL3N0eWxlcy54bWy0nU1z2zgShu9btf+BpdPuIZG/nbjGmXKcZO3aOOOJnM0ZIiELa5LQklRsz69fAKQkyE1QaKB9SSyJ/RDE2y+ABvXx2+9PRZ784lUtZHk+2n+7N0p4mcpMlPfnox93X968GyV1w8qM5bLk56NnXo9+//D3v/32eFY3zzmvEwUo67MiPR/Nm2ZxNh7X6ZwXrH4rF7xUL85kVbBGPazuxwWrHpaLN6ksFqwRU5GL5nl8sLd3MuowlQ9FzmYi5Z9kuix42Zj4ccVzRZRlPReLekV79KE9yipbVDLlda0uushbXsFEucbsHwFQIdJK1nLWvFUX07XIoFT4/p75q8g3gGMc4AAATlL+hGO86xhjFWlzRIbjnKw5IrM4YY2xAHXWZHMU5WDVr2Mdyxo2Z/XcJnJco47XuOdC91GRnl3fl7Ji01yRlOqJEi4xYP2vun79n/mTP5nn9SWMPigvZDL9xGdsmTe1fljdVt3D7pH574ssmzp5PGN1KsT56E4Uyj7f+GPyXRZMZdvjGWd1c1EL1vvi/KKs+8PSGj491qfMWXmvXv/F8vMRL9/8mGyfZP3UVGSKzKo3kwsdOO7a3P5vXcli/ag96sVlKwsqQ07acUG9ymdfZfrAs0mjXjgf7elTqSd/XN9WQlbK+5vnJrwQVyLLeGkdV85Fxn/Oefmj5tnm+T+/GPt2T6RyWaq/D09PjBJ5nX1+SvlCDwbq1ZIV6szfdECuj/7fKna/66G+w+ec6QEw2UdHHOiI2roWg1i+uBA89/CVuEevxD1+Je7JK3FPX4n77pW474m5oszUkGaO96Du4vi6YBfHN+t3cXyzfBfHN6t3cXyzeBfHN2t3cXyzdBfHNyvdnEamBFmoKfE5qCnxGagp8fmnKfHZpynxuacp8ZmnKfF5pynxWdcuD5JrlcRlE02bSdmUsuFJw5/iaaxULFPa0PD0DMIrkoskwLTjRjerRdNSZh57chLPubHR9UAiZ8lM3C8rVf/GNpOXv3iuKtGEZZniEQIr3iwr3+v3yOCKz3jFy5RTpjEdNBclT8plMSXIxAW7J2PxMiPuvhWRZAgomCqKoymNZGTG/SrqJvlG0/mGFT/7G0z89G8w8fO/wcQvAAzm4zLPOVkXdTSinupoRB3W0Yj6rc1Pqn7raET91tGI+q2jxffbnWhyM/h5TbSXudRbsNFnnYj7kqmJMH7Y7Ta3kltWsfuKLeaJ3sOLxn6U2XNyRzGUr0lUi1ej/6W6SFEu4/vvRq1u9Lx6RbPonCynDSqjJixftquO+FRgTXx/bOT6IqqaTLR+LMFI9U2vObR4FLbctDK+YRtW/AD60kOkzeuQBK3MZfpAM2hcPS94pdbOD9GkLzLP5SPP6IiTppJtrnkZ/HOxmLNamBLKK2B11zC5YYvoxt7mTJQ0mnx+UzCRJ3RT19XdzdfkTi504ao7hgb4UTaNLMiY3cbLP37y6T9pGnihSpvymehqL4jqcwO7FAQTSEuSGRFJrW9EKUjmR8P7N3+eSlZlNLRbVT8bSzeciDhhxaJdPhB4S415j5Wg2AUzvP+wSuidJipT3ZHArH2bejn9L0/jh7pvMtGrzGjOH8vGbACZJauJpsPFLwG2cPHTv1FTTQ86fwkudgsXf7FbOKqLvcxZXQuK+0HbPKrLXfGorze+iO94MpfVbJnTdeAKSNaDKyBZF8p8WZQ15RUbHuEFGx719RKmjOER7PwY3r8qkZGJYWBUShgYlQwGRqWBgZEKEH/L14LF3/m1YPE3gFsY0RLAglHlGen0T3QzwYJR5ZmBUeWZgVHlmYFR5dnhp4TPZmoRTDfFWEiqnLOQdBNN2fBiIStWPRMhP+f8nhFsfra020rO9Du4Zdm+z5MAqXebc8LFdoujEvknnxI07TZnKZ/LPOPVwD6W2Lxf9/37AZqq7CYLlnabxXaY4Xht0H0V9/MmmczXe8425mRvZ+SqtNwK231CPR2BsIOBsBueiWWxamgrxVbwoX+wyYmt4KPdwZs5byvy2DMSnvNkd+RmPbcVeeoZCc/5zjPSjGNbkUN5+IlVD72JcDqUP+tqxJF8p0NZtA7uPe1QIq0j+1LwdCiLtqySXKSp3teG6vh5xh3vZx53PMZFbgrGTm6Kt6/ciCGDfee/hJ6D4oZR04L1LeeXoYdmAeg1lv65lO2esx1/YN4v6RV/rSb9suZJL+fQfPrCi7M17rh71nsAciO8RyI3wntIciO8xiZnOGqQclO8Rys3wnvYciPQ4xecI3DjF4zHjV8wPmT8gpSQ8StiXeBGeC8Q3Ai0USECbdSItYMbgTIqCA8yKqSgjQoRaKNCBNqocEmGMyqMxxkVxocYFVJCjAopaKNCBNqoEIE2KkSgjQoRaKMGrvad4UFGhRS0USECbVSIQBvVrBcjjArjcUaF8SFGhZQQo0IK2qgQgTYqRKCNChFoo0IE2qgQgTIqCA8yKqSgjQoRaKNCBNqoZjM+wqgwHmdUGB9iVEgJMSqkoI0KEWijQgTaqBCBNipEoI0KESijgvAgo0IK2qgQgTYqRKCNam50RRgVxuOMCuNDjAopIUaFFLRRIQJtVIhAGxUi0EaFCLRRIQJlVBAeZFRIQRsVItBGhYih/Oxur9lvCLdj9/G7ni7Ugf/NrK5R3+3PgdqoQ3/UqlVulqnpvVgfpXxI1p/N2oKYesMPIqa5kGaL2nFL2Oaa2/mou5x/XA5/8sSmG3Eh3fdSuvfxm/uqAH7kGwn2VI6GUt6OBEXe0VCm25Fg1Xk0NPrakWAaPBoadI0vV2+oUNMRCB4aZqzgfUf40GhthcMuHhqjrUDYw0MjsxUIO3hoPLYCjxM9OL+MPvbsp5P1eyMBYSgdLcKpmzCUllCr1XAMjeErmpvgq56b4Cujm4DS04nBC+tGoRV2o8KkhjbDSh1uVDcBKzUkBEkNMOFSQ1Sw1BAVJjUcGLFSQwJW6vDB2U0IkhpgwqWGqGCpISpMajiVYaWGBKzUkICVOnJCdmLCpYaoYKkhKkxquLjDSg0JWKkhASs1JARJDTDhUkNUsNQQFSY1qJLRUkMCVmpIwEoNCUFSA0y41BAVLDVEDUltdlG2pEYpbIXjFmFWIG5CtgJxg7MVGFAtWdGB1ZJFCKyWoFYrzXHVki2am+CrnpvgK6ObgNLTicEL60ahFXajwqTGVUt9Uocb1U3ASo2rlpxS46qlQalx1dKg1LhqyS01rlrqkxpXLfVJHT44uwlBUuOqpUGpcdXSoNS4asktNa5a6pMaVy31SY2rlvqkjpyQnZhwqXHV0qDUuGrJLTWuWuqTGlct9UmNq5b6pMZVS06pcdXSoNS4amlQaly15JYaVy31SY2rlvqkxlVLfVLjqiWn1LhqaVBqXLU0KDWuWrpRIcLvAzf6GcQNyEnBqibZ8c1mUWe4YvW8Ybtvb+LJP8qK1zL/xbPktTvoa2TfjB+3fjZGn838sJQ6vlF9r7+Y2fogVNZ+IWd3CnPgdbb+fRcdrNuWdD950z1tLqG7EWz+7n6Qp/5rdeBBd9e0/utS/3CN9Zz1UzjmbLB96Vw1MO2+BsrRvu57RNef6TLfIvqytY4vGzUN23Tm6uhOmU23t8dtdXHbfke7G+2/gTYbfw52bGthVwNXH3Hb1ULVnmneCqL+uC4zBXjsftunbWn2xFqUev2S5/kNa4+WC/ehOZ817av7e+bT/y9en7ZfZOeMr8ys4QSMtxvTPhzOk/a7xbu3MzjzWA+NPd1t3lsT29Obtq3+qj/8HwAA//8DAFBLAwQUAAYACAAAACEA/OW8rC4BAABLAwAAFAAAAHdvcmQvd2ViU2V0dGluZ3MueG1snNHNbsIwDADg+6S9Q5U7pKCBUEXhMk3aedsDhMSlEUlcxWGFt5/bAavEhe6Sf3+ynfX25F32DZEshlLMprnIIGg0NuxL8fX5NlmJjJIKRjkMUIozkNhunp/WbdHC7gNS4peUsRKo8LoUdUpNISXpGryiKTYQ+LLC6FXibdxLr+Lh2Ew0+kYlu7POprOc5/lSXJj4iIJVZTW8oj56CKmPlxEcixiotg1dtfYRrcVomogaiLge7349r2y4MbOXO8hbHZGwSlMu5pJRT3H4LO9X3v0Bi3HA/A5YajiNM1YXQ3Lk0LFmnLO8OdYMnP8lMwDIJFOPUubXvsouViVVK6qHIoxLanHjzr7rkdfF+z5gVDvHEv96xh+X9XA3cv3d1C/h1J93JQi5+QEAAP//AwBQSwMEFAAGAAgAAAAhAB+1+Kb/AQAAdAYAABIAAAB3b3JkL2ZvbnRUYWJsZS54bWy8k9FumzAUhu8n7R2Q7xsMJTRFJZXWNdJudjF1D+AYE6xiG/k4IXn7HRtCI0WdyqQVBJjf53yc89s8PB5VGx2EBWl0SZIFJZHQ3FRS70ry+2VzsyIROKYr1hotSnISQB7XX7889EVttIMI8zUUipekca4r4hh4IxSDhemExsnaWMUcvtpdrJh93Xc33KiOObmVrXSnOKU0JyPGfoRi6lpy8d3wvRLahfzYihaJRkMjOzjT+o/QemOrzhouALBn1Q48xaSeMEl2BVKSWwOmdgtsZqwooDA9oWGk2jfAch4gvQLkXBznMVYjI8bMS46s5nHyiSOrC86/FXMBgMpVzSxKevY19rnMsYZBc0kU84paTriT8h4pXvzYaWPZtkUSrnqECxcFsL9j//4RhuIYdN8CWY+/QtQXminMfJFKQPRT9NEvo5gOAR3TBkSCMQfWloT6bnJ6S5c0wyvFUUZiH8gbZkF42BBIB7lmSrans2oDN0x00vHmrB+Ylb76YQrkDif2sKUleaaUps+bDRmUpCRPqNytlt9GJfXfCsf9qNxOCvUKD5zwmgwcHjhTDH4zHpy4cuSJqS1W9o4T3oHBCe9I+glO0PzSiQz/+DSbFO9E+tb33524n+1EK9GKd5zYhL3gz2y2E9BLgHlOZFd7Ijhx93/2xDiA9R8AAAD//wMAUEsDBBQABgAIAAAAIQBKWq4+PgEAAGMCAAARAAgBZG9jUHJvcHMvY29yZS54bWwgogQBKKAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACMklFLwzAQx98Fv0PJe5ukExmh7UBlLzoQNlF8C+mtCyZpSOK6fXvTunVO9+Djcb/7cfdPitlOq2QLzsvWlIhmBCVgRFtL05ToZTVPpyjxgZuaq9ZAifbg0ay6viqEZaJ18OxaCy5I8Ek0Gc+ELdEmBMsw9mIDmvssEiY2163TPMTSNdhy8cEbwDkht1hD4DUPHPfC1I5GdFDWYlTaT6cGQS0wKNBggsc0o/jEBnDaXxwYOj9ILcPewkX02BzpnZcj2HVd1k0GNO5P8dviaTmcmkrTZyUAVX0+ivuwiFGuJdR3+2oZZJM8SqUgprlRBf6L9FMOtrJ/jepmIMayOJzGhAMeoE7iSuz7gGPndXL/sJqjKid5nlKSUrqiOaNTRsh7gX/Nn4T6sMC/jTk5Nx4F1bDx+beovgAAAP//AwBQSwMEFAAGAAgAAAAhAOirSLDSAQAA1gMAABAACAFkb2NQcm9wcy9hcHAueG1sIKIEASigAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAnFPBbtswDL0P2D8YujeK06IYAkXFkGLoYVsDxG3PmkwnwmRJkNig2dePshtX2XqqT++R1NMTSYubl95WB4jJeLdi9WzOKnDat8btVuyh+XbxhVUJlWuV9Q5W7AiJ3cjPn8Qm+gARDaSKJFxasT1iWHKe9B56lWaUdpTpfOwVEo077rvOaLj1+rkHh3wxn19zeEFwLbQXYRJko+LygB8Vbb3O/tJjcwykJ0UDfbAKQf7MJ63gU0A0HpVtTA9yQeGJiI3aQZK14CMQTz62SS7mgo9IrPcqKo3UO1nXV4IXXHwNwRqtkLoqfxgdffIdVveD1SqfF7wsEWR/C/o5GjxKuqGk4rtxo5ERkLGodlGF/au7iYmtVhbW9HDZKZtA8LeAuAOVh7pRJvs74PIAGn2skvlDY12w6pdKkNu1YgcVjXLIxrKRDNiGhFE2Bi1pT3yAZVmJzVU2OYLzwoEMHgifuxtuSPcdvQ3fMVuXZgcPo9XCTunsdMc/qmvfB+Wov3xC1ODf6SE0/jZvxmsPz4PF1J8M7rdB6Tycy8ty/kVGbCkKLQ10mskUEHf0gmizPp11O2hPNf8n8kY9jr+prK9nc/qGFTrFaBGm/0f+BQAA//8DAFBLAwQUAAYACAAAACEAtPOKZfUAAABDAQAAGQAAAGRvY01ldGFkYXRhL0xhYmVsSW5mby54bWxUkMtqwzAQRX/FaC/LUp1YNrYD3RXSVb9Aj1Es0CNY09BS+u+Vu2p3lwtzOHfmy0cMzQP24nNaCG870kAy2fp0W8g7OipJU1Alq0JOsJBPKOSyziboMAWlIVx9waZCUpmOciEb4n1irJgNoipt9GbPJTtsTY4sO+cNMNGJjkV/vx6EV0BlFSryF9t4u5Av1wulnnpB5dCdaS+kpNpyTkFreRrHUyek+T6MlQ5QDzhpIuCWa3z7ld5t1fcILwdtEG6UUtdNZ8dpz5WjI1eaCjsY23FudT9UmskJIeGzx7KQ+o8dYn4c9JrZOrP/29cfAAAA//8DAFBLAQItABQABgAIAAAAIQCA0VzDeQEAAJIFAAATAAAAAAAAAAAAAAAAAAAAAABbQ29udGVudF9UeXBlc10ueG1sUEsBAi0AFAAGAAgAAAAhAPuZZUcfAQAA4AIAAAsAAAAAAAAAAAAAAAAAsgMAAF9yZWxzLy5yZWxzUEsBAi0AFAAGAAgAAAAhALUSmO6EAwAAKg4AABEAAAAAAAAAAAAAAAAAAgcAAHdvcmQvZG9jdW1lbnQueG1sUEsBAi0AFAAGAAgAAAAhANZks1H0AAAAMQMAABwAAAAAAAAAAAAAAAAAtQoAAHdvcmQvX3JlbHMvZG9jdW1lbnQueG1sLnJlbHNQSwECLQAUAAYACAAAACEAlrWt4vEFAABQGwAAFQAAAAAAAAAAAAAAAADrDAAAd29yZC90aGVtZS90aGVtZTEueG1sUEsBAi0AFAAGAAgAAAAhACnzMqOWBwAA5hgAABEAAAAAAAAAAAAAAAAADxMAAHdvcmQvc2V0dGluZ3MueG1sUEsBAi0AFAAGAAgAAAAhAFyKXRELAQAAhQIAABwAAAAAAAAAAAAAAAAA1BoAAHdvcmQvX3JlbHMvc2V0dGluZ3MueG1sLnJlbHNQSwECLQAUAAYACAAAACEAhADSPwkLAAABbgAADwAAAAAAAAAAAAAAAAAZHAAAd29yZC9zdHlsZXMueG1sUEsBAi0AFAAGAAgAAAAhAPzlvKwuAQAASwMAABQAAAAAAAAAAAAAAAAATycAAHdvcmQvd2ViU2V0dGluZ3MueG1sUEsBAi0AFAAGAAgAAAAhAB+1+Kb/AQAAdAYAABIAAAAAAAAAAAAAAAAArygAAHdvcmQvZm9udFRhYmxlLnhtbFBLAQItABQABgAIAAAAIQBKWq4+PgEAAGMCAAARAAAAAAAAAAAAAAAAAN4qAABkb2NQcm9wcy9jb3JlLnhtbFBLAQItABQABgAIAAAAIQDoq0iw0gEAANYDAAAQAAAAAAAAAAAAAAAAAFMtAABkb2NQcm9wcy9hcHAueG1sUEsBAi0AFAAGAAgAAAAhALTzimX1AAAAQwEAABkAAAAAAAAAAAAAAAAAWzAAAGRvY01ldGFkYXRhL0xhYmVsSW5mby54bWxQSwUGAAAAAA0ADQBSAwAAhzEAAAAA');
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerFalse(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}