This module provides an API for the Edit in Excel functionality in Business Central.

This module can be used to:
- Enable Edit in Excel functionality on new pages
- Modify the behaviour of the Edit in Excel functionality

### How to download an Edit in Excel file
```
procedure Example()
var
    EditinExcel: Codeunit "Edit in Excel";
    EditinExcelFilters: Codeunit "Edit in Excel Filters";
    FileName: Text;
begin
    EditinExcelFilters.AddFieldV2('Journal_Batch_Name', Enum::"Edit in Excel Filter Type"::Equal, JournalBatchName, Enum::"Edit in Excel Edm Type"::"Edm.String");
    EditinExcelFilters.AddFieldV2('Journal_Template_Name', Enum::"Edit in Excel Filter Type"::Equal, JournalTemplateName, Enum::"Edit in Excel Edm Type"::"Edm.String");
    FileName := StrSubstNo('%1 (%2, %3)', CurrPage.Caption, JournalBatchName, JournalTemplateName);
    EditinExcel.EditPageInExcel(CopyStr(CurrPage.Caption, 1, 240), Page::"Example page", EditinExcelFilters, FileName);
end;
```

### How to override Edit in Excel functionality
```
[EventSubscriber(ObjectType::Codeunit, Codeunit::"Edit in Excel", 'OnEditInExcelWithFilters', '', false, false)]
local procedure OnEditInExcelWithFilters(ServiceName: Text[240]; var EditinExcelFilters: Codeunit "Edit in Excel Filters"; SearchFilter: Text; var Handled: Boolean)
begin
    // Note: Since EditinExcelFilters is sent by var, you can simply modify the filters and not handle the entire flow by not setting Handled := True
    if HandleOnEditInExcel(ServiceName, EditinExcelFilters, SearchFilter) then
        Handled := True;
end;
```

### How to generate your own Excel file
```
procedure CreateExcelFile(ServiceName: Text[250]; EditinExcelFilters: Codeunit "Edit in Excel Filters"; SearchFilter: Text)
var
    EditinExcelWorkbook: Codeunit "Edit in Excel Workbook";
    FileName: Text;
begin
    // Initialize the workbook
    EditinExcelWorkbook.Initialize(ServiceName);

    // Add columns that should be shown to the user
    EditinExcelWorkbook.AddColumn(Rec.FieldCaption(Code), 'Code');
    EditinExcelWorkbook.AddColumn(Rec.FieldCaption(Name), 'Name');

    // Add any filters from the page (see below for how to create filters). Note: It's allowed to filter on columns not added to the excel file
    EditinExcelWorkbook.SetFilters(EditinExcelFilters);

    // Download the excel file
    FileName := 'ExcelFileName.xlsx';
    DownloadFromStream(EditinExcelWorkbook.ExportToStream(), DialogTitleTxt, '', '*.*', FileName);
end;
```

### How to create filters
```
procedure CreateExcelFilters()
var
    EditinExcelFilters: Codeunit "Edit in Excel Filters";
begin
    // Let's add a simple filter "Blocked = False"
    EditinExcelFilters.AddFieldV2('Blocked', Enum::"Edit in Excel Filter Type"::Equal, 'false', Enum::"Edit in Excel Edm Type"::"Edm.Boolean");

    // Now the filter "No. = 10000|20000"
    EditinExcelFilters.AddFieldV2('No_', Enum::"Edit in Excel Filter Collection Type"::"or", Enum::"Edit in Excel Edm Type"::"Edm.String")
                        .AddFilterValue(Enum::"Edit in Excel Filter Type"::Equal, '10000')
                        .AddFilterValue(Enum::"Edit in Excel Filter Type"::Equal, '20000');

    // Finally let's add a range, "Amount = 1000..2000"
    EditinExcelFilters.AddFieldV2('Amount', Enum::"Edit in Excel Filter Collection Type"::"and", Enum::"Edit in Excel Edm Type"::"Edm.Decimal")
                        .AddFilterValue(Enum::"Edit in Excel Filter Type"::"Greater or Equal", '1000')
                        .AddFilterValue(Enum::"Edit in Excel Filter Type"::"Less or Equal", '2000');

    // Since we did not clear EditinExcelFilters in between, the current filter is "(Blocked = false) and (No_ = 10000|20000) and (Amount = 1000..2000)"
    // In other words, all the filters are added together.
end;
```

