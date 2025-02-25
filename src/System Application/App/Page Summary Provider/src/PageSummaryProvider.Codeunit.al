// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Integration;

/// <summary>
/// Exposes functionality that gets page summary for a selected page.
/// This codeunit is exposed as a webservice and hence all functions are available through OData calls.
/// </summary>
codeunit 2718 "Page Summary Provider"
{
    Access = Public;

    #region OData API functions
    /// <summary>
    /// Gets page summary for a given Page ID and bookmark.
    /// </summary>
    //  <param name="PageId">The ID of the page for which to retrieve page summary.</param>
    //  <param name="Bookmark">The Bookmark of the page for which to retrieve page summary.</param>
    /// <returns>Text value for the page summary in JSON format.</returns>
    /// <example>
    /// {
    ///   "version":"1.1",
    ///   "pageCaption":"Customer Card",
    ///   "pageType":"Card",
    ///   "summaryType":"Brick",
    ///   "cardPageId": "0",
    ///   "url":"https://businesscentral.dynamics.com/?company=CRONUS%20International%20Ltd.&amp;page=22&amp;bookmark=27%3bEgAAAAJ7CDAAMQA5ADAANQA4ADkAMw%3d%3",
    ///   "fields":[
    ///      {"caption":"No.","fieldValue":"01445544","fieldType":"Code", "tooltip":"Specifies the number of the customer."},
    ///      {"caption":"Name","fieldValue":"Progressive Home Furnishings","fieldType":"Text","tooltip":"Specifies the customer's name. This name will appear on all sales documents for the customer."},
    ///      {"caption":"Contact","fieldValue":"Mr. Scott Mitchell","fieldType":"Text", "tooltip":"Specifies the name of the person you regularly contact when you do business with this customer."},
    ///      {"caption":"Balance Due (LCY)","fieldValue":"1.499,03","fieldType":"Decimal","tooltip":"Specifies the payment amount that the customer owes for completed sales."}],
    ///   "recordFields":[
    ///      {"caption":"No.","fieldValue":"01121212","fieldType":"Code","tooltip":"Specifies the number of the customer."},
    ///      {"caption":"Name","fieldValue":"Spotsmeyer's Furnishings","fieldType":"Text","tooltip":"Specifies the customer's name. This name will appear on all sales documents for the customer."},
    ///      {"caption":"Balance (LCY)","fieldValue":"0","fieldType":"Decimal","tooltip":"Specifies the payment amount that the customer owes for completed sales. This value is also known as the customer's balance."},
    ///      {"caption":"Balance Due (LCY)","fieldValue":"0","fieldType":"Decimal","tooltip":"Specifies payments from the customer that are overdue per today's date."},
    ///      {"caption":"Credit Limit (LCY)","fieldValue":"0","fieldType":"Decimal","tooltip":"Specifies the maximum amount you allow the customer to exceed the payment balance before warnings are issued."},
    ///      {"caption":"Blocked","fieldValue":" ","fieldType":"Option","tooltip":"Specifies which transactions with the customer that cannot be processed, for example, because the customer is insolvent."},
    ///      {"caption":"Privacy Blocked","fieldValue":"No","fieldType":"Boolean","tooltip":"Specifies whether to limit access to data for the data subject during daily operations. This is useful, for example, when protecting data from changes while it is under privacy review."},
    ///      {"caption":"Salesperson Code","fieldValue":"JR","fieldType":"Code","tooltip":"Specifies a code for the salesperson who normally handles this customer's account."},
    ///      {"caption":"Service Zone Code","fieldValue":"X","fieldType":"Code","tooltip":"Specifies the code for the service zone that is assigned to the customer."},
    ///      {"caption":"Address","fieldValue":"612 South Sunset Drive","fieldType":"Text","tooltip":"Specifies the customer's address. This address will appear on all sales documents for the customer."}
    ///      {"caption":"Payments This Year","fieldValue":"0","fieldType":"Decimal","tooltip":"Specifies the sum of payments received from the customer in the current fiscal year."},
    ///      {"caption":"Last Date Modified","fieldValue":"08/02/24","fieldType":"Date","tooltip":"Specifies when the customer card was last modified."}]
    /// }
    ///
    /// In case of an error:
    /// {
    ///   "version":"1.1",
    ///   "pageCaption":"Customer Card",
    ///   "pageType":"Card",
    ///   "summaryType":"Caption",
    ///   "error":[
    ///     "code":"InvalidBookmark"
    ///     "message":"The bookmark is invalid."
    ///   ]
    /// }
    /// </example>
    procedure GetPageSummary(PageId: Integer; Bookmark: Text): Text
    var
        SummaryProviderImpl: Codeunit "Page Summary Provider Impl.";
    begin
        exit(SummaryProviderImpl.GetPageSummary(PageId, Bookmark, true));
    end;

    /// <summary>
    /// Gets page summary for a given Page ID and System ID.
    /// </summary>
    //  <param name="PageId">The ID of the page for which to retrieve page summary.</param>
    //  <param name="SystemId">The system ID of the record in the page for which to retrieve page summary.
    //  Following GUID formats are supported:
    //  1. 32 digits separated by hyphens.
    //  2. 32 digits separated by hyphens and enclosed in braces.
    //  </param>
    /// <returns>Text value for the page summary in JSON format.</returns>
    /// <example>
    /// {
    ///   "version":"1.1",
    ///   "pageCaption":"Customer Card",
    ///   "pageType":"Card",
    ///   "summaryType":"Brick",
    ///   "cardPageId": "0",
    ///   "url":"https://businesscentral.dynamics.com/?company=CRONUS%20International%20Ltd.&amp;page=22&amp;bookmark=27%3bEgAAAAJ7CDAAMQA5ADAANQA4ADkAMw%3d%3",
    ///   "fields":[
    ///      {"caption":"No.","fieldValue":"01445544","fieldType":"Code", "tooltip":"Specifies the number of the customer."},
    ///      {"caption":"Name","fieldValue":"Progressive Home Furnishings","fieldType":"Text","tooltip":"Specifies the customer's name. This name will appear on all sales documents for the customer."},
    ///      {"caption":"Contact","fieldValue":"Mr. Scott Mitchell","fieldType":"Text", "tooltip":"Specifies the name of the person you regularly contact when you do business with this customer."},
    ///      {"caption":"Balance Due (LCY)","fieldValue":"1.499,03","fieldType":"Decimal","tooltip":"Specifies the payment amount that the customer owes for completed sales."}],
    ///   "recordFields":[
    ///      {"caption":"No.","fieldValue":"01121212","fieldType":"Code","tooltip":"Specifies the number of the customer."},
    ///      {"caption":"Name","fieldValue":"Spotsmeyer's Furnishings","fieldType":"Text","tooltip":"Specifies the customer's name. This name will appear on all sales documents for the customer."},
    ///      {"caption":"Balance (LCY)","fieldValue":"0","fieldType":"Decimal","tooltip":"Specifies the payment amount that the customer owes for completed sales. This value is also known as the customer's balance."},
    ///      {"caption":"Balance Due (LCY)","fieldValue":"0","fieldType":"Decimal","tooltip":"Specifies payments from the customer that are overdue per today's date."},
    ///      {"caption":"Credit Limit (LCY)","fieldValue":"0","fieldType":"Decimal","tooltip":"Specifies the maximum amount you allow the customer to exceed the payment balance before warnings are issued."},
    ///      {"caption":"Blocked","fieldValue":" ","fieldType":"Option","tooltip":"Specifies which transactions with the customer that cannot be processed, for example, because the customer is insolvent."},
    ///      {"caption":"Privacy Blocked","fieldValue":"No","fieldType":"Boolean","tooltip":"Specifies whether to limit access to data for the data subject during daily operations. This is useful, for example, when protecting data from changes while it is under privacy review."},
    ///      {"caption":"Salesperson Code","fieldValue":"JR","fieldType":"Code","tooltip":"Specifies a code for the salesperson who normally handles this customer's account."},
    ///      {"caption":"Service Zone Code","fieldValue":"X","fieldType":"Code","tooltip":"Specifies the code for the service zone that is assigned to the customer."},
    ///      {"caption":"Address","fieldValue":"612 South Sunset Drive","fieldType":"Text","tooltip":"Specifies the customer's address. This address will appear on all sales documents for the customer."}
    ///      {"caption":"Payments This Year","fieldValue":"0","fieldType":"Decimal","tooltip":"Specifies the sum of payments received from the customer in the current fiscal year."},
    ///      {"caption":"Last Date Modified","fieldValue":"08/02/24","fieldType":"Date","tooltip":"Specifies when the customer card was last modified."}]
    /// }
    ///
    /// In case of an error:
    /// {
    ///   "version":"1.1",
    ///   "pageCaption":"Customer Card",
    ///   "pageType":"Card",
    ///   "summaryType":"Caption",
    ///   "error":[
    ///     "code":"InvalidSystemId"
    ///     "message":"The system id is invalid."
    ///   ]
    /// }
    /// </example>
    procedure GetPageSummaryBySystemID(PageId: Integer; SystemId: Guid): Text
    var
        SummaryProviderImpl: Codeunit "Page Summary Provider Impl.";
    begin
        exit(SummaryProviderImpl.GetPageSummary(PageId, SystemId, true));
    end;

    /// <summary>
    /// Gets page information such as page caption and and page type.
    /// </summary>
    //  <param name="PageId">The ID of the page for which to retrieve page summary.</param>
    /// <returns>Text value for the page summary in JSON format.</returns>
    /// <example>
    /// {
    ///   "version":"1.1",
    ///   "pageCaption":"Customer Card",
    ///   "pageType":"Card",
    ///   "summaryType":"Caption",
    /// }
    ///
    /// In case of error:
    /// {
    ///   "version":"1.1",
    ///   "pageCaption":"Customer Card",
    ///   "pageType":"Card",
    ///   "summaryType":"Caption",
    ///   "error":[
    ///     "code":"error code"
    ///     "message":"error message"
    ///   ]
    /// }
    /// </example>
    procedure GetPageSummary(PageId: Integer): Text
    var
        SummaryProviderImpl: Codeunit "Page Summary Provider Impl.";
    begin
        exit(SummaryProviderImpl.GetPageSummary(PageId, '', true));
    end;

    /// <summary>
    /// Gets page summary for a given Page ID and specified parameters in JSON format.
    /// </summary>
    //  <param name="PageId">The ID of the page for which to retrieve page summary.</param>
    //  <param name="Parameters">Parameters in JSON format to be used for fetching page summary.</param>
    /// <returns>Text value for the page summary in JSON format.</returns>
    /// <example>
    /// {
    ///   "version":"1.1",
    ///   "pageCaption":"Customer Card",
    ///   "pageType":"Card",
    ///   "summaryType":"Brick",
    ///   "cardPageId": "0",
    ///   "url":"https://businesscentral.dynamics.com/?company=CRONUS%20International%20Ltd.&amp;page=22&amp;bookmark=27%3bEgAAAAJ7CDAAMQA5ADAANQA4ADkAMw%3d%3",
    ///   "fields":[
    ///      {"caption":"No.","fieldValue":"01445544","fieldType":"Code", "tooltip":"Specifies the number of the customer."},
    ///      {"caption":"Name","fieldValue":"Progressive Home Furnishings","fieldType":"Text","tooltip":"Specifies the customer's name. This name will appear on all sales documents for the customer."},
    ///      {"caption":"Contact","fieldValue":"Mr. Scott Mitchell","fieldType":"Text", "tooltip":"Specifies the name of the person you regularly contact when you do business with this customer."},
    ///      {"caption":"Balance Due (LCY)","fieldValue":"1.499,03","fieldType":"Decimal","tooltip":"Specifies the payment amount that the customer owes for completed sales."}],
    ///   "recordFields":[
    ///      {"caption":"No.","fieldValue":"01121212","fieldType":"Code","tooltip":"Specifies the number of the customer."},
    ///      {"caption":"Name","fieldValue":"Spotsmeyer's Furnishings","fieldType":"Text","tooltip":"Specifies the customer's name. This name will appear on all sales documents for the customer."},
    ///      {"caption":"Balance (LCY)","fieldValue":"0","fieldType":"Decimal","tooltip":"Specifies the payment amount that the customer owes for completed sales. This value is also known as the customer's balance."},
    ///      {"caption":"Balance Due (LCY)","fieldValue":"0","fieldType":"Decimal","tooltip":"Specifies payments from the customer that are overdue per today's date."},
    ///      {"caption":"Credit Limit (LCY)","fieldValue":"0","fieldType":"Decimal","tooltip":"Specifies the maximum amount you allow the customer to exceed the payment balance before warnings are issued."},
    ///      {"caption":"Blocked","fieldValue":" ","fieldType":"Option","tooltip":"Specifies which transactions with the customer that cannot be processed, for example, because the customer is insolvent."},
    ///      {"caption":"Privacy Blocked","fieldValue":"No","fieldType":"Boolean","tooltip":"Specifies whether to limit access to data for the data subject during daily operations. This is useful, for example, when protecting data from changes while it is under privacy review."},
    ///      {"caption":"Salesperson Code","fieldValue":"JR","fieldType":"Code","tooltip":"Specifies a code for the salesperson who normally handles this customer's account."},
    ///      {"caption":"Service Zone Code","fieldValue":"X","fieldType":"Code","tooltip":"Specifies the code for the service zone that is assigned to the customer."},
    ///      {"caption":"Address","fieldValue":"612 South Sunset Drive","fieldType":"Text","tooltip":"Specifies the customer's address. This address will appear on all sales documents for the customer."}
    ///      {"caption":"Payments This Year","fieldValue":"0","fieldType":"Decimal","tooltip":"Specifies the sum of payments received from the customer in the current fiscal year."},
    ///      {"caption":"Last Date Modified","fieldValue":"08/02/24","fieldType":"Date","tooltip":"Specifies when the customer card was last modified."}]
    /// }
    ///
    /// In case of an error:
    /// {
    ///   "version":"1.1",
    ///   "pageCaption":"Customer Card",
    ///   "pageType":"Card",
    ///   "summaryType":"Caption",
    ///   "error":[
    ///     "code":"InvalidSystemId"
    ///     "message":"The system id is invalid."
    ///   ]
    /// }
    /// </example>
    procedure GetPageSummary(Parameters: Text): Text
    var
        SummaryProviderImpl: Codeunit "Page Summary Provider Impl.";
    begin
        exit(SummaryProviderImpl.GetPageSummary(Parameters));
    end;

    /// <summary>
    /// Gets the web client url info for a given Page ID and System ID.
    /// </summary>
    //  <param name="PageId">The ID of the page for which to retrieve the url info.</param>
    //  <param name="SystemId">The system ID of the record in the page for which to retrieve the url info.
    //  Following GUID formats are supported:
    //  1. 32 digits separated by hyphens.
    //  2. 32 digits separated by hyphens and enclosed in braces.
    //  </param>
    /// <returns>Text value for the page url info in JSON format.</returns>
    /// <example>
    /// {
    ///   "version":"1.1",
    ///   "url":"https://businesscentral.dynamics.com/?company=CRONUS%20International%20Ltd.&amp;page=22&amp;bookmark=27%3bEgAAAAJ7CDAAMQA5ADAANQA4ADkAMw%3d%3",
    /// }
    ///
    /// In case of an error:
    /// {
    ///   "version":"1.1",
    ///   "error":[
    ///     "code":"InvalidSystemId"
    ///     "message":"The system id is invalid."
    ///   ]
    /// }
    /// </example>
    procedure GetPageUrlBySystemID(PageId: Integer; SystemId: Guid): Text
    var
        SummaryProviderImpl: Codeunit "Page Summary Provider Impl.";
    begin
        exit(SummaryProviderImpl.GetPageUrlBySystemID(PageId, SystemId));
    end;

    /// <summary>
    /// Gets the current version of the Page Summary Provider.
    /// </summary>
    /// <returns>Text value for the current version of Page Summary Provider.</returns>
    procedure GetVersion(): Text[30]
    var
        SummaryProviderImpl: Codeunit "Page Summary Provider Impl.";
    begin
        exit(SummaryProviderImpl.GetVersion());
    end;
    #endregion

    /// <summary>
    /// Gets page summary for a given Page ID and specified parameters record.
    /// </summary>
    //  <param name="PageId">The ID of the page for which to retrieve page summary.</param>
    //  <param name="Parameters">Parameters record that is used to generate the page summary.</param>
    /// <returns>Text value for the page summary in JSON format.</returns>
    /// <example>
    /// {
    ///   "version":"1.1",
    ///   "pageCaption":"Customer Card",
    ///   "pageType":"Card",
    ///   "summaryType":"Brick",
    ///   "cardPageId": "0",
    ///   "url":"https://businesscentral.dynamics.com/?company=CRONUS%20International%20Ltd.&amp;page=22&amp;bookmark=27%3bEgAAAAJ7CDAAMQA5ADAANQA4ADkAMw%3d%3",
    ///   "fields":[
    ///      {"caption":"No.","fieldValue":"01445544","fieldType":"Code", "tooltip":"Specifies the number of the customer."},
    ///      {"caption":"Name","fieldValue":"Progressive Home Furnishings","fieldType":"Text","tooltip":"Specifies the customer's name. This name will appear on all sales documents for the customer."},
    ///      {"caption":"Contact","fieldValue":"Mr. Scott Mitchell","fieldType":"Text", "tooltip":"Specifies the name of the person you regularly contact when you do business with this customer."},
    ///      {"caption":"Balance Due (LCY)","fieldValue":"1.499,03","fieldType":"Decimal","tooltip":"Specifies the payment amount that the customer owes for completed sales."}],
    ///   "recordFields":[
    ///      {"caption":"No.","fieldValue":"01121212","fieldType":"Code","tooltip":"Specifies the number of the customer."},
    ///      {"caption":"Name","fieldValue":"Spotsmeyer's Furnishings","fieldType":"Text","tooltip":"Specifies the customer's name. This name will appear on all sales documents for the customer."},
    ///      {"caption":"Balance (LCY)","fieldValue":"0","fieldType":"Decimal","tooltip":"Specifies the payment amount that the customer owes for completed sales. This value is also known as the customer's balance."},
    ///      {"caption":"Balance Due (LCY)","fieldValue":"0","fieldType":"Decimal","tooltip":"Specifies payments from the customer that are overdue per today's date."},
    ///      {"caption":"Credit Limit (LCY)","fieldValue":"0","fieldType":"Decimal","tooltip":"Specifies the maximum amount you allow the customer to exceed the payment balance before warnings are issued."},
    ///      {"caption":"Blocked","fieldValue":" ","fieldType":"Option","tooltip":"Specifies which transactions with the customer that cannot be processed, for example, because the customer is insolvent."},
    ///      {"caption":"Privacy Blocked","fieldValue":"No","fieldType":"Boolean","tooltip":"Specifies whether to limit access to data for the data subject during daily operations. This is useful, for example, when protecting data from changes while it is under privacy review."},
    ///      {"caption":"Salesperson Code","fieldValue":"JR","fieldType":"Code","tooltip":"Specifies a code for the salesperson who normally handles this customer's account."},
    ///      {"caption":"Service Zone Code","fieldValue":"X","fieldType":"Code","tooltip":"Specifies the code for the service zone that is assigned to the customer."},
    ///      {"caption":"Address","fieldValue":"612 South Sunset Drive","fieldType":"Text","tooltip":"Specifies the customer's address. This address will appear on all sales documents for the customer."}
    ///      {"caption":"Payments This Year","fieldValue":"0","fieldType":"Decimal","tooltip":"Specifies the sum of payments received from the customer in the current fiscal year."},
    ///      {"caption":"Last Date Modified","fieldValue":"08/02/24","fieldType":"Date","tooltip":"Specifies when the customer card was last modified."}]
    /// }
    ///
    /// In case of an error:
    /// {
    ///   "version":"1.1",
    ///   "pageCaption":"Customer Card",
    ///   "pageType":"Card",
    ///   "summaryType":"Caption",
    ///   "error":[
    ///     "code":"InvalidSystemId"
    ///     "message":"The system id is invalid."
    ///   ]
    /// }
    /// </example>
    procedure GetPageSummary(PageSummaryParameters: Record "Page Summary Parameters"): Text
    var
        SummaryProviderImpl: Codeunit "Page Summary Provider Impl.";
    begin
        exit(SummaryProviderImpl.GetPageSummary(PageSummaryParameters));
    end;

    /// <summary>
    /// Allows changing which fields and values are returned when fetching page summary.
    /// </summary>
    //  <param name="PageId">The ID of the page for which to retrieve page summary.</param>
    //  <param name="RecId">The underlying record id of the source table for the page we are retrieving, based on the bookmark.</param>
    //  <param name="FieldsJsonArray">The Json array that will be used to summarize fields if the event is handled.</param>
    //  <param name="Handled">Specifies whether the event has been handled and no further execution should occur.</param>
    [IntegrationEvent(false, false)]
    internal procedure OnBeforeGetPageSummary(PageId: Integer; RecId: RecordId; var FieldsJsonArray: JsonArray; var Handled: Boolean)
    begin
    end;

    /// <summary>
    /// Allows changing which fields are shown when fetching page summary, including their order.
    /// </summary>
    //  <param name="PageId">The ID of the page for which we are retrieving page summary.</param>
    //  <param name="RecId">The underlying record id of the source table for the page we are retrieving.</param>
    //  <param name="FieldList">The List of fields that will be returned.</param>
    [IntegrationEvent(false, false)]
    internal procedure OnAfterGetSummaryFields(PageId: Integer; RecId: RecordId; var FieldList: List of [Integer])
    begin
    end;

    /// <summary>
    /// Allows changing which fields and values are returned just before sending the response.
    /// </summary>
    //  <param name="PageId">The ID of the page for which to retrieve page summary.</param>
    //  <param name="RecId">The underlying record id of the source table for the page we are retrieving.</param>
    //  <param name="FieldsJsonArray">Allows overriding which fields and values are being returned.</param>
    [IntegrationEvent(false, false)]
    internal procedure OnAfterGetPageSummary(PageId: Integer; RecId: RecordId; var FieldsJsonArray: JsonArray)
    begin
    end;
}