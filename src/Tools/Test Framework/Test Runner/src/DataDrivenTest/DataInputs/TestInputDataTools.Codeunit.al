// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

/// <summary>
/// Resolves data tool placeholders embedded in test input values.
/// Supports named placeholders, date formulas, and datetime formulas.
/// Resolution is lazy and registrations are transactional.
/// </summary>
codeunit 130465 "Test Input Data Tools"
{
    SingleInstance = true;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        TestInputPlaceholderImpl: Codeunit "Test Input Placeholder Impl.";
        TestInputDateImpl: Codeunit "Test Input Date Impl.";

    /// <summary>
    /// Gets the bare name from a single, valid named-placeholder definition.
    /// Reads the raw scalar without resolving an existing registration.
    /// Raises an error if the definition is not a complete named token with a valid name.
    /// </summary>
    /// <param name="Definition">A raw scalar containing exactly one complete named-placeholder token.</param>
    /// <returns>The validated bare name, preserving its authored casing.</returns>
    procedure GetPlaceholderName(Definition: Codeunit "Test Input Json"): Text
    begin
        exit(TestInputPlaceholderImpl.GetPlaceholderName(Definition));
    end;

    /// <summary>
    /// Reports whether text contains the named-placeholder marker, including incomplete references.
    /// Does not resolve text or look up registrations.
    /// </summary>
    /// <param name="InputText">The text to inspect without resolving placeholders.</param>
    /// <returns>True if the exact named-placeholder marker occurs, even in an incomplete token; otherwise false.</returns>
    procedure ContainsNamedPlaceholderMarker(InputText: Text): Boolean
    begin
        exit(TestInputPlaceholderImpl.ContainsNamedPlaceholderMarker(InputText));
    end;

    /// <summary>
    /// Inserts or replaces a value using its full name and the current company.
    /// </summary>
    /// <param name="Name">A bare, case-insensitive name of 1 to 250 ASCII letters, digits, underscores, or hyphens.</param>
    /// <param name="Value">Literal replacement text. Complete supported placeholder tokens are not allowed.</param>
    procedure SetPlaceholder(Name: Text; Value: Text)
    begin
        TestInputPlaceholderImpl.SetPlaceholder(Name, Value);
    end;

    /// <summary>
    /// Inserts or replaces the exact full name and company key without committing.
    /// A blank company registers a shared fallback. Values must not contain supported placeholder tokens.
    /// </summary>
    /// <param name="Name">A bare, case-insensitive name of 1 to 250 ASCII letters, digits, underscores, or hyphens.</param>
    /// <param name="Value">Literal replacement text. Complete supported placeholder tokens are not allowed.</param>
    /// <param name="Company">A company key of at most 30 characters. Blank registers the shared fallback.</param>
    procedure SetPlaceholderForCompany(Name: Text; Value: Text; Company: Text)
    begin
        TestInputPlaceholderImpl.SetPlaceholderForCompany(Name, Value, Company);
    end;

    /// <summary>
    /// Gets a value using its full name and the current company, then the shared-company fallback.
    /// Returns false and clears Value when no registration exists.
    /// </summary>
    /// <param name="Name">A bare, case-insensitive name of 1 to 250 ASCII letters, digits, underscores, or hyphens.</param>
    /// <param name="Value">The registered value with platform-standard line breaks, or an empty string when no registration exists.</param>
    /// <returns>True if a current-company or shared registration exists, including one with an empty value; otherwise false.</returns>
    procedure GetPlaceholder(Name: Text; var Value: Text): Boolean
    begin
        exit(TestInputPlaceholderImpl.GetPlaceholder(Name, Value));
    end;

    /// <summary>
    /// Gets the exact company value before its shared fallback, using the same full name.
    /// An explicitly blank company reads only the shared row. An empty registered value is a match.
    /// Returns false and clears Value when no registration exists.
    /// </summary>
    /// <param name="Name">A bare, case-insensitive name of 1 to 250 ASCII letters, digits, underscores, or hyphens.</param>
    /// <param name="Value">The registered value with platform-standard line breaks, or an empty string when no registration exists.</param>
    /// <param name="Company">A company key of at most 30 characters. Blank reads only the shared registration.</param>
    /// <returns>True if the requested company or its shared fallback has a registration, including an empty value; otherwise false.</returns>
    procedure GetPlaceholderForCompany(Name: Text; var Value: Text; Company: Text): Boolean
    begin
        exit(TestInputPlaceholderImpl.GetPlaceholderForCompany(Name, Value, Company));
    end;

    /// <summary>
    /// Deletes the exact full-name/current-company registration, without following shared fallback.
    /// </summary>
    /// <param name="Name">A bare, case-insensitive name of 1 to 250 ASCII letters, digits, underscores, or hyphens.</param>
    /// <returns>True if the current-company registration was deleted; false if that exact key did not exist.</returns>
    procedure DeletePlaceholder(Name: Text): Boolean
    begin
        exit(TestInputPlaceholderImpl.DeletePlaceholder(Name));
    end;

    /// <summary>
    /// Deletes only the exact key. Blank company targets the shared row, not all companies.
    /// Returns false if that key does not exist.
    /// </summary>
    /// <param name="Name">A bare, case-insensitive name of 1 to 250 ASCII letters, digits, underscores, or hyphens.</param>
    /// <param name="Company">A company key of at most 30 characters. Blank deletes only the shared registration.</param>
    /// <returns>True if the exact registration was deleted; false if it did not exist. Shared fallback is never followed.</returns>
    procedure DeletePlaceholderForCompany(Name: Text; Company: Text): Boolean
    begin
        exit(TestInputPlaceholderImpl.DeletePlaceholderForCompany(Name, Company));
    end;

    /// <summary>
    /// Deletes every placeholder registration across all names and companies without committing.
    /// </summary>
    procedure DeleteAllPlaceholders()
    begin
        TestInputPlaceholderImpl.DeleteAllPlaceholders();
    end;

    /// <summary>
    /// Resolves named, date, and datetime tokens on every call.
    /// Named tokens use their full name and the current company. Unknown names remain unchanged.
    /// Only the original input is scanned; replacement text is never scanned again.
    /// </summary>
    /// <param name="InputText">The raw text value from the test input.</param>
    /// <returns>The text with known placeholders resolved.</returns>
    procedure ResolveText(InputText: Text): Text
    begin
        exit(TestInputPlaceholderImpl.ResolveText(InputText));
    end;

    /// <summary>
    /// Resolves a value to a Date.
    /// If the value is a $DateFormula-...$ placeholder, calculates the date via CalcDate relative to WorkDate.
    /// Otherwise evaluates the resolved text as a date.
    /// </summary>
    /// <param name="InputText">The raw text value.</param>
    /// <returns>The resolved Date.</returns>
    procedure ResolveAsDate(InputText: Text): Date
    begin
        exit(TestInputDateImpl.ResolveAsDate(InputText));
    end;

    /// <summary>
    /// Resolves a value to a DateTime.
    /// Supports date formulas with midnight, explicit time, or millisecond precision.
    /// </summary>
    /// <param name="InputText">The raw text value.</param>
    /// <returns>The resolved DateTime.</returns>
    procedure ResolveAsDateTime(InputText: Text): DateTime
    begin
        exit(TestInputDateImpl.ResolveAsDateTime(InputText));
    end;
}
