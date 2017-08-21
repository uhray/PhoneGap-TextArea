//
//  TextArea.m
//
//  Created by Tha Leang on 8/7/14.
//
//

#import "TextArea.h"

@interface TextArea()<UITextViewDelegate> {
  
  NSString *titleString;
  NSString *confirmButtonString;
  NSString *cancelButtonString;
  NSString *placeHolderString;
  NSString *bodyText;
  
  CDVInvokedUrlCommand *cmd;
  UITextView *textView;
  CGRect originalTextViewFrame;
}

@end

@implementation TextArea

- (void)openTextView:(CDVInvokedUrlCommand*)command {
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillChangeFrameNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
  UIColor *redColor = [UIColor colorWithRed:(216/255.0) green:(73/255.0) blue:(67/255.0) alpha:1];
  
  cmd = command;
  titleString = command.arguments[0];
  confirmButtonString = command.arguments[1];
  cancelButtonString = command.arguments[2];
  placeHolderString = command.arguments[3];
  bodyText = command.arguments[4];
  
  // create controllers
  UIViewController *viewController = [[UIViewController alloc] init];
  UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];
  
  // create view
  textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, viewController.view.frame.size.width, viewController.view.frame.size.height)];
  
  // load body for textView and add border
  NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
  paragraphStyle.headIndent = 5.0;
  paragraphStyle.firstLineHeadIndent = 5.0;
  paragraphStyle.tailIndent = -5.0;
  NSDictionary *attrsDictionary = @{NSFontAttributeName: [UIFont fontWithName:@"AppleSDGothicNeo-Medium" size:16], NSParagraphStyleAttributeName: paragraphStyle};
  [textView setDelegate:self];
  [textView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
  [textView setTintColor:redColor];
  
  if ([bodyText isEqualToString:@""] || [bodyText isEqualToString:placeHolderString]) {
    textView.attributedText = [[NSAttributedString alloc] initWithString:placeHolderString attributes:attrsDictionary];
    [textView setTextColor:[UIColor lightGrayColor]];
  }
  else {
    textView.attributedText = [[NSAttributedString alloc] initWithString:bodyText attributes:attrsDictionary];
    [textView setTextColor:[UIColor blackColor]];
  }
  
  [viewController setTitle:titleString];
  [textView becomeFirstResponder];

  [navController.navigationBar setBarTintColor:redColor];
  UIBarButtonItem *cancelBarBtnItem = [[UIBarButtonItem alloc] initWithTitle:cancelButtonString style:UIBarButtonItemStylePlain target:self action:@selector(cancelBtnPressed:)];
  [cancelBarBtnItem setTintColor:[UIColor whiteColor]];
  UIBarButtonItem *confirmBarBtnItem = [[UIBarButtonItem alloc] initWithTitle:confirmButtonString style:UIBarButtonItemStylePlain target:self action:@selector(confirmBtnPressed:)];
  [confirmBarBtnItem setTintColor:[UIColor whiteColor]];
  
  // add view
  [navController.topViewController.navigationItem setLeftBarButtonItem:cancelBarBtnItem animated:YES];
  [navController.topViewController.navigationItem setRightBarButtonItem:confirmBarBtnItem animated:YES];
  [viewController.view addSubview:textView];
  
  // present the controller
  [self.viewController presentViewController:navController animated:YES completion:NULL];
  
}

#pragma Actions

- (void)cancelBtnPressed: (id) sender {
  [self clearoutPlaceholder];
  [self.viewController dismissViewControllerAnimated:YES completion:^(void) {
    [self removeObservers];
    NSString *escapeString = [self escapedString:textView.text];
    NSString *jsonString = [NSString stringWithFormat:@"{\"status\" : \"cancel\",\"body\" : \"%@\"}", escapeString];
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:jsonString];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:cmd.callbackId];
  }];
}

- (void)confirmBtnPressed: (id) sender {
  [self clearoutPlaceholder];
  [self removeObservers];
  [self.viewController dismissViewControllerAnimated:YES completion:^(void) {
    NSString *sendingString = @"";
    if (![textView.text isEqualToString:placeHolderString]) {
      sendingString = [textView.text copy];
    }
    NSString *escapeString = [self escapedString:sendingString];
    NSString *jsonString = [NSString stringWithFormat:@"{\"status\" : \"success\",\"body\" : \"%@\"}", escapeString];
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:jsonString];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:cmd.callbackId];
  }];
}

- (NSString *) escapedString:(NSString *) text {
  NSData *dataenc = [text dataUsingEncoding:NSUTF16StringEncoding];
  NSString *escapeString = [[NSString alloc]initWithData:dataenc encoding:NSUTF16StringEncoding];
  escapeString = [escapeString stringByReplacingOccurrencesOfString:@"\n" withString:@"%0A"];
  escapeString = [escapeString stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
  escapeString = [escapeString stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
  return escapeString;
}

- (void) clearoutPlaceholder {
  if ([textView.text isEqualToString:placeHolderString]) {
    textView.text = @"";
  }
}

- (void) removeObservers {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma TextView Delegate methods

- (void)textViewDidBeginEditing:(UITextView *)tView
{
  if ([tView.text isEqualToString:placeHolderString]) {
    tView.text = @"";
    tView.textColor = [UIColor blackColor];
  }
  [tView becomeFirstResponder];
}

- (void)textViewDidEndEditing:(UITextView *)tView
{
  if ([tView.text isEqualToString:@""]) {
    tView.text = placeHolderString;
    tView.textColor = [UIColor lightGrayColor];
  }
  [tView resignFirstResponder];
}

#pragma keyboard Notifications

- (void)keyboardWillShow:(NSNotification*)notification {
  [self moveTextViewForKeyboard:notification up:YES];
}

- (void)keyboardWillHide:(NSNotification*)notification {
  [self moveTextViewForKeyboard:notification up:NO];
}

- (void)moveTextViewForKeyboard:(NSNotification*)notification up:(BOOL)up {
  
  if ([UIApplication sharedApplication].statusBarOrientation != UIInterfaceOrientationPortrait) {
    return;
  }
  
  NSDictionary *userInfo = [notification userInfo];
  NSTimeInterval animationDuration;
  UIViewAnimationCurve animationCurve;
  CGRect keyboardRect;
  
  [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
  animationDuration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
  keyboardRect = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
  keyboardRect = [self.viewController.view convertRect:keyboardRect fromView:nil];
  
  [UIView beginAnimations:@"ResizeForKeyboard" context:nil];
  [UIView setAnimationDuration:animationDuration];
  [UIView setAnimationCurve:animationCurve];
  
  if (up == YES) {
    CGFloat keyboardTop = keyboardRect.origin.y;
    CGRect newTextViewFrame = textView.frame;
    originalTextViewFrame = textView.frame;
    newTextViewFrame.size.height = keyboardTop - textView.frame.origin.y;
    
    textView.frame = newTextViewFrame;
  } else {
    // Keyboard is going away (down) - restore original frame
    textView.frame = originalTextViewFrame;
  }
  
  [UIView commitAnimations];
}

@end
