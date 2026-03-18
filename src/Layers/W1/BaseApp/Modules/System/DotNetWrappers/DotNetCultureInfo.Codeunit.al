namespace System.Globalization;

using System;
using System.DateTime;

codeunit 3002 DotNet_CultureInfo
{
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        DotNetCultureInfo: DotNet CultureInfo;

    /// <summary>
    /// Points this codeunit to the specified culture.
    /// </summary>
    /// <param name="CultureName">The culture language tag, for example "en-US".</param>
    procedure GetCultureInfoByName(CultureName: Text)
    begin
        DotNetCultureInfo := DotNetCultureInfo.GetCultureInfo(CultureName);
    end;

    /// <summary>
    /// Points this codeunit to the specified culture.
    /// </summary>
    /// <param name="LanguageId">The culture LCID, for example 1033.</param>
    procedure GetCultureInfoById(LanguageId: Integer)
    begin
        DotNetCultureInfo := DotNetCultureInfo.GetCultureInfo(LanguageId);
    end;

    /// <summary>
    /// Points this codeunit to the invariant culture.
    /// </summary>
    procedure InvariantCulture()
    begin
        DotNetCultureInfo := DotNetCultureInfo.InvariantCulture;
    end;

    /// <summary>
    /// Gets the name of the culture.
    /// </summary>
    /// <returns>The name of the culture, for example "en-US".</returns>
    /// <remarks>Make sure you initialize this codeunit (for example with the procedure <see cref="GetCultureInfoById"/>) before calling this function.</remarks>
    procedure Name(): Text
    begin
        exit(DotNetCultureInfo.Name);
    end;

    /// <summary>
    /// Gets the language code (LCID) of the culture.
    /// </summary>
    /// <returns>The LCID of the culture, for example 1033.</returns>
    /// <remarks>Make sure you initialize this codeunit (for example with the procedure <see cref="GetCultureInfoById"/>) before calling this function.</remarks>
    procedure LCID(): Integer
    begin
        exit(DotNetCultureInfo.LCID);
    end;

    /// <summary>
    /// Gets the name of the current culture.
    /// </summary>
    /// <returns>The name of the current culture, for example "en-US".</returns>
    procedure CurrentCultureName(): Text
    begin
        Clear(DotNetCultureInfo);
        exit(DotNetCultureInfo.CurrentCulture.Name);
    end;

    /// <summary>
    /// Gets a string representation of the culture.
    /// </summary>
    /// <returns>A string representation of the culture.</returns>
    /// <remarks>Make sure you initialize this codeunit (for example with the procedure <see cref="GetCultureInfoById"/>) before calling this function.</remarks>
    procedure ToString(): Text
    begin
        exit(DotNetCultureInfo.ToString());
    end;

    /// <summary>
    /// Gets the language name for the culture.
    /// </summary>
    /// <returns>A code (two or three letters long), for example "en" or "quz".</returns>
    /// <remarks>Make sure you initialize this codeunit (for example with the procedure <see cref="GetCultureInfoById"/>) before calling this function.</remarks>
    procedure TwoLetterISOLanguageName(): Text
    begin
        exit(DotNetCultureInfo.TwoLetterISOLanguageName);
    end;

    /// <summary>
    /// Gets the three-letter windows language name.
    /// </summary>
    /// <returns>The three letter Windows language name, for example "ENU".</returns>
    procedure ThreeLetterWindowsLanguageName(): Text
    begin
        exit(DotNetCultureInfo.ThreeLetterWindowsLanguageName);
    end;

    /// <summary>
    /// Gets the date-time format info for the culture.
    /// </summary>
    /// <param name="DotNet_DateTimeFormatInfo">The returned date-time format info.</param>
    /// <remarks>Make sure you initialize this codeunit (for example with the procedure <see cref="GetCultureInfoById"/>) before calling this function.</remarks>
    procedure DateTimeFormat(var DotNet_DateTimeFormatInfo: Codeunit DotNet_DateTimeFormatInfo)
    begin
        DotNet_DateTimeFormatInfo.SetDateTimeFormatInfo(DotNetCultureInfo.DateTimeFormat);
    end;

    [Scope('OnPrem')]
    procedure GetCultureInfo(var DotNetCultureInfo2: DotNet CultureInfo)
    begin
        DotNetCultureInfo2 := DotNetCultureInfo;
    end;

    [Scope('OnPrem')]
    procedure SetCultureInfo(DotNetCultureInfo2: DotNet CultureInfo)
    begin
        DotNetCultureInfo := DotNetCultureInfo2;
    end;
}