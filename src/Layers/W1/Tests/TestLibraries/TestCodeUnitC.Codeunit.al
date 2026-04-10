codeunit 132510 TestCodeUnitC
{
    Permissions = TableData TestTableC = rimd;

    trigger OnRun()
    var
        TestTableC: Record TestTableC;
    begin
        TestTableC.Init();

        Clear(TestTableC.IntegerField);

        TestTableC.Insert();
    end;
}

