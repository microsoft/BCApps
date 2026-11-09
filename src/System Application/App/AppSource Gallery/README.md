This module provides functionality for listing AppSource apps.

Use this module to do the following:
- list AppSource products
- view AppSource product details
- start installation of AppSource product

Product details open as a non-modal in-client page. Retrieving product details can
initialize persistent user settings, so opening the page must not require the
absence of a write transaction or explicitly commit the caller's changes.
