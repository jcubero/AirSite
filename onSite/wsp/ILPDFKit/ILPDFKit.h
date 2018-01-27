//
//  ILPDFKit.h
//  ILPDFKit
//
//  Created by Derek Blair on 2016-03-19.
//  Copyright © 2016 Derek Blair. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for ILPDFKit.
FOUNDATION_EXPORT double ILPDFKitVersionNumber;

//! Project version string for ILPDFKit.
FOUNDATION_EXPORT const unsigned char ILPDFKitVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <ILPDFKit/PublicHeader.h>


#import "ILPDFKit/Model/Objects/ILPDFDictionary.h"
#import "ILPDFKit/Model/Objects/ILPDFArray.h"
#import "ILPDFKit/Model/Objects/ILPDFStream.h"
#import "ILPDFKit/Model/Objects/ILPDFString.h"
#import "ILPDFKit/Model/Objects/ILPDFName.h"
#import "ILPDFKit/Model/Objects/ILPDFNumber.h"
#import "ILPDFKit/Model/Objects/ILPDFNull.h"

#import "ILPDFKit/Model/ILPDFForm.h"
#import "ILPDFKit/Model/ILPDFPage.h"
#import "ILPDFKit/Model/ILPDFDocument.h"
#import "ILPDFKit/Model/ILPDFFormContainer.h"

#import "ILPDFKit/View/ILPDFView.h"
#import "ILPDFKit/View/ILPDFWidgetAnnotationView.h"
#import "ILPDFKit/View/ILPDFFormTextField.h"
#import "ILPDFKit/Controller/ILPDFViewController.h"
#import "ILPDFKit/Utility/ILPDFUtility.h"


#import <QuartzCore/QuartzCore.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// This is the color for all pdf forms.
#define ILPDFWidgetColor [UIColor colorWithRed:0.7 green:0.85 blue:1.0 alpha:0.7]

// PDF uses ASCII for readable characters, but allows any 8 bit value unlike ASCII, so we use an extended ASCII set here.
// The character mapped to encoded bytes over 127 have no significance, and are octal escaped if needed to be read as text in the PDF file itself.
#define ILPDFStringCharacterEncoding NSISOLatin1StringEncoding

// Character macros
#define isWS(c) ((c) == 0 || (c) == 9 || (c) == 10 || (c) == 12 || (c) == 13 || (c) == 32)
#define isDelim(c) ((c) == '(' || (c) == ')' || (c) == '<' || (c) == '>' || (c) == '[' || (c) == ']' || (c) == '{' || (c) == '}' || (c) == '/' ||  (c) == '%')
#define isODelim(c) ((c) == '(' ||  (c) == '<' ||  (c) == '[')
#define isCDelim(c) ((c) == ')' ||  (c) == '>' ||  (c) == ']')

#define ILPDFFormMinFontSize 8
#define ILPDFFormMaxFontSize 22



