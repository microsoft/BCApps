// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Utilities;

/// <summary>
/// Provides value parsing utilities for Quality Management.
/// Handles parsing of ranges, numeric values, and other text-to-value conversions.
/// 
/// This codeunit follows the Single Responsibility Principle by focusing solely
/// on parsing concerns: converting text representations into typed values.
/// </summary>
codeunit 20434 "Qlty. Value Parsing"
{
    Access = Internal;

    /// <summary>
    /// Attempts to parse simple range notation (min..max) into separate minimum and maximum decimal values.
    /// Handles the common 90% use case of range specifications in quality inspections.
    /// 
    /// Examples:
    /// - "10..20" → OutMin=10, OutMax=20, returns true
    /// - "5.5..10.5" → OutMin=5.5, OutMax=10.5, returns true
    /// - "-5..-1" → OutMin=-5, OutMax=-1, returns true
    /// - "Invalid" → returns false
    /// - "10" → returns false (not a range)
    /// </summary>
    /// <param name="InputText">The text containing a range in format "minValue..maxValue"</param>
    /// <param name="MinValueInRange">Output: The minimum value from the range</param>
    /// <param name="MaxValueInRange">Output: The maximum value from the range</param>
    /// <returns>True if successfully parsed as a simple range; False if input doesn't match simple range pattern</returns>
    procedure AttemptSplitSimpleRangeIntoMinMax(InputText: Text; var MinValueInRange: Decimal; var MaxValueInRange: Decimal): Boolean
    var
        OfParts: List of [Text];
        Temp: Text;
    begin
        Clear(MaxValueInRange);
        Clear(MinValueInRange);

        if InputText.Contains('..') then
            if InputText.IndexOf('..') > 0 then begin
                OfParts := InputText.Split('..');
                if OfParts.Count() = 2 then begin
                    OfParts.Get(1, Temp);
                    if Evaluate(MinValueInRange, Temp) then begin
                        OfParts.Get(2, Temp);
                        if Evaluate(MaxValueInRange, Temp) then
                            exit(true);
                    end;
                end;
            end;
    end;
}
