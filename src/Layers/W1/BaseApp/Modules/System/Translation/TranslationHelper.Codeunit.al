namespace System.IO;

using System.Globalization;
using System.Reflection;

codeunit 53 "Translation Helper"
{
    // The codeunit is designed to clean the defined functions from codunit 43 (Language Management).
    // The functions are needed exclusively to provide means to translate TextConst variables.
    // This functionality should be provided in the platform and this codeunit should be deleted.


    trigger OnRun()
    begin
    end;

    var
        SavedGlobalLanguageId: Integer;

    // <summary>
    // Sets the global language by language code.
    // If the language code is invalid the global language remains unchanged, no error in thrown.
    // </summary>
    // <param name="LanguageCode">The code of the language to be set as global</param>
    procedure SetGlobalLanguageByCode(LanguageCode: Code[10])
    var
        Language: Codeunit Language;
        LanguageId: Integer;
    begin

        if LanguageCode = '' then
            exit;

        LanguageId := Language.GetLanguageId(LanguageCode);
        SetGlobalLanguageById(LanguageId);
    end;

    // <summary>
    // Sets the global language by language id.
    // If the language id is 0 the global language remains unchanged, no error in thrown.
    // </summary>
    // <param name="LanguageId">The Id of the language to be set as global</param>
    procedure SetGlobalLanguageById(LanguageId: Integer)
    begin
        if LanguageId <> 0 then begin
            SavedGlobalLanguageId := GlobalLanguage;
            GlobalLanguage(LanguageId);
        end;
    end;

    // <summary>
    // Sets the global language to the default application language ID.
    // </summary>
    procedure SetGlobalLanguageToDefault()
    var
        Language: Codeunit Language;
    begin
        SetGlobalLanguageById(Language.GetDefaultApplicationLanguageId());
    end;

    // <summary>
    // Restores the previously set global language
    // </summary>
    // <seealso>SetGlobalLanguageByCode</seealso>
    procedure RestoreGlobalLanguage()
    begin

        if (SavedGlobalLanguageId <> 0) and (SavedGlobalLanguageId <> GlobalLanguage) then begin
            GlobalLanguage(SavedGlobalLanguageId);
            SavedGlobalLanguageId := 0;
        end;
    end;

    // <summary>
    // Retrieves a translated field caption
    // </summary>
    // <param name="LanguageCode">The code of the language to which the field caption will be translated.</param>
    // <param name="TableID">The ID of the table where the field is located.</param>
    // <param name="FieldId">The ID of the field for which the caption will be translated.</param>
    // <returns>The field's caption translated in the specified language</returns>
    procedure GetTranslatedFieldCaption(LanguageCode: Code[10]; TableID: Integer; FieldId: Integer) TranslatedText: Text
    var
        "Field": Record "Field";
        Language: Codeunit Language;
        LanguageIdToSet: Integer;
        CurrentLanguageId: Integer;
    begin

        CurrentLanguageId := GlobalLanguage;
        LanguageIdToSet := Language.GetLanguageIdOrDefault(LanguageCode);
        if (LanguageCode <> '') and (LanguageIdToSet <> CurrentLanguageId) then begin
            GlobalLanguage(LanguageIdToSet);
            Field.Get(TableID, FieldId);
            TranslatedText := Field."Field Caption";
            GlobalLanguage(CurrentLanguageId);
        end else begin
            Field.Get(TableID, FieldId);
            TranslatedText := Field."Field Caption";
        end;
    end;
}

