codeunit 110500 "Demotool System Constants"
{
    // Be careful when updating this file that all labels are marked something like "!Build ...!"
    // We populate these during the build process and they should not be exported containing actual details.


    trigger OnRun()
    begin
    end;

    procedure ProductVersion(): Text[80]
    begin
        // Should be 'Build Product Version' with ! on both sides.
        exit('!Build Product Version!');
    end;
}

