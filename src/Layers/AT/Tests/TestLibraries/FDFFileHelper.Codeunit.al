codeunit 144003 FDFFileHelper
{

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        hashTable: DotNet Hashtable;
        fdfFilePatternTxt: Label '<<\s/V\s\((?<Value>.*?)\)/T\s\((?<Key>.*?)\)>>';
        CountErr: Label 'Count is wrong. Expected: %1 - Actual: %2';
        ContainsErr: Label 'The key="%1" could not be found in the FDF file';

    [Scope('OnPrem')]
    procedure ReadFdfFile(fileName: Text)
    var
        regEx: DotNet Regex;
        regExMatch: DotNet Match;
        textFile: File;
        fileStream: InStream;
        str: Text;
    begin
        textFile.Open(fileName, TEXTENCODING::Windows);
        textFile.CreateInStream(fileStream);
        regEx := regEx.Regex(fdfFilePatternTxt);
        hashTable := hashTable.Hashtable();
        while not fileStream.EOS do begin
            fileStream.ReadText(str);
            regExMatch := regEx.Match(str);
            if regExMatch.Success then
                hashTable.Add(regExMatch.Groups.Item('Key').Value, regExMatch.Groups.Item('Value').Value);
        end;
        textFile.Close();
    end;

    [Scope('OnPrem')]
    procedure GetValue("key": Text): Text
    begin
        if Contains(key) then
            exit(hashTable.Item(key));
    end;

    [Scope('OnPrem')]
    procedure Contains("key": Text): Boolean
    begin
        Assert.IsTrue(hashTable.ContainsKey(key), StrSubstNo(ContainsErr, key));
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure VerifyCount(expected: Integer)
    begin
        Assert.AreEqual(expected, hashTable.Count, StrSubstNo(CountErr, expected, hashTable.Count));
    end;
}

