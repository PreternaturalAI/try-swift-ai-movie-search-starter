//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swift

/*
 This extension allow to parse the content of an Apple receipt from the AppStore.
 
 Reference documentation
 https://developer.apple.com/library/archive/releasenotes/General/ValidateAppStoreReceipt/Chapters/ReceiptFields.html
 */
extension PKCS7 {

    public struct ReceiptInfo {

        /// CFBundleIdentifier in Info.plist
        public fileprivate(set) var bundleIdentifier: String?

        /// CFBundleVersion (in iOS) or CFBundleShortVersionString (in macOS) in Info.plist
        public fileprivate(set) var bundleVersion: String?

        /// CFBundleVersion (in iOS) or CFBundleShortVersionString (in macOS) in Info.plist
        public fileprivate(set) var originalApplicationVersion: String?

        /// Opaque value used, with other data, to compute the SHA-1 hash during validation.
        public fileprivate(set) var opaqueValue: Data?

        /// SHA-1 hash, used to validate the receipt.
        public fileprivate(set) var sha1: Data?

        public fileprivate(set) var receiptCreationDate: Date?
        public fileprivate(set) var receiptCreationDateString: String?
        public fileprivate(set) var receiptExpirationDate: Date?
        public fileprivate(set) var receiptExpirationDateString: String?
        public fileprivate(set) var inAppPurchases: [InAppPurchaseInfo]?
    }

    public struct InAppPurchaseInfo {
        public fileprivate(set) var quantity: UInt64?
        public fileprivate(set) var productId: String?
        public fileprivate(set) var transactionId: String?
        public fileprivate(set) var originalTransactionId: String?
        public fileprivate(set) var purchaseDate: Date?
        public fileprivate(set) var originalPurchaseDate: Date?
        public fileprivate(set) var expiresDate: Date?
        public fileprivate(set) var isInIntroOfferPeriod: UInt64?
        public fileprivate(set) var cancellationDate: Date?
        public fileprivate(set) var webOrderLineItemId: UInt64?
    }
    
    func parseDate(_ dateString: String) -> Date? {
        let rfc3339DateFormatter = DateFormatter()
        rfc3339DateFormatter.locale = Locale(identifier: "en_US_POSIX")
        rfc3339DateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        rfc3339DateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        return rfc3339DateFormatter.date(from: dateString)
    }

    public func receipt() -> ReceiptInfo? {
        guard let block = mainBlock.findOid(.pkcs7data) else { return nil }
        guard let receiptBlock = block.parent?.sub?.last?.sub(0)?.sub(0) else { return nil }
        var receiptInfo = ReceiptInfo()

        for item in receiptBlock.sub ?? [] {
            let fieldType = (item.sub(0)?.value as? Data)?.toIntValue() ?? 0
            let fieldValueString = item.sub(2)?.sub?.first?.value as? String
            switch fieldType {
            case 2:
                receiptInfo.bundleIdentifier = fieldValueString

            case 3:
                receiptInfo.bundleVersion = fieldValueString

            case 4:
                receiptInfo.opaqueValue = item.sub(2)?.rawValue

            case 5:
                receiptInfo.sha1 = item.sub(2)?.rawValue

            case 19:
                receiptInfo.originalApplicationVersion = fieldValueString

            case 12:
                guard let fieldValueString = fieldValueString else { continue }
                receiptInfo.receiptCreationDateString = fieldValueString
                receiptInfo.receiptCreationDate = parseDate(fieldValueString)

            case 21:
                guard let fieldValueString = fieldValueString else { continue }
                receiptInfo.receiptExpirationDateString = fieldValueString
                receiptInfo.receiptExpirationDate = parseDate(fieldValueString)

            case 17:
                let subItems = item.sub(2)?.sub?.first?.sub ?? []
                if receiptInfo.inAppPurchases == nil {
                    receiptInfo.inAppPurchases = []
                }
                receiptInfo.inAppPurchases?.append(inAppPurchase(subItems))

            default:
                break
            }
        }
        return receiptInfo
    }
    
    private func inAppPurchase(_ subItems: [ASN1Object]) -> InAppPurchaseInfo {
        var inAppPurchaseInfo = InAppPurchaseInfo()
        subItems.forEach { subItem in
            let fieldType = (subItem.sub(0)?.value as? Data)?.toIntValue() ?? 0
            let fieldValue = subItem.sub(2)?.sub?.first?.value
            switch fieldType {
            case 1701:
                inAppPurchaseInfo.quantity = (fieldValue as? Data)?.toIntValue()
            case 1702:
                inAppPurchaseInfo.productId = fieldValue as? String
            case 1703:
                inAppPurchaseInfo.transactionId = fieldValue as? String
            case 1705:
                inAppPurchaseInfo.originalTransactionId = fieldValue as? String
            case 1704:
                if let fieldValueString = fieldValue as? String {
                    inAppPurchaseInfo.purchaseDate = parseDate(fieldValueString)
                }
            case 1706:
                if let fieldValueString = fieldValue as? String {
                    inAppPurchaseInfo.originalPurchaseDate = parseDate(fieldValueString)
                }
            case 1708:
                if let fieldValueString = fieldValue as? String {
                    inAppPurchaseInfo.expiresDate = parseDate(fieldValueString)
                }
            case 1719:
                inAppPurchaseInfo.isInIntroOfferPeriod = (fieldValue as? Data)?.toIntValue()
            case 1712:
                if let fieldValueString = fieldValue as? String {
                    inAppPurchaseInfo.cancellationDate = parseDate(fieldValueString)
                }
            case 1711:
                inAppPurchaseInfo.webOrderLineItemId = (fieldValue as? Data)?.toIntValue()
            default:
                break
            }
        }
        return inAppPurchaseInfo
    }

}
