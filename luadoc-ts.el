;;; luadoc-ts.el --- Tree-sitter support for Luadocs -*- lexical-binding: t; -*-

;; Author: Noah Peart <noah.v.peart@gmail.com>
;; URL: https://github.com/nverno/luadoc-ts
;; Version: 0.0.1
;; Package-Requires: ((emacs "29.1"))
;; Created: 26 April 2024
;; Keywords:

;; This file is not part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.

;;; Commentary:
;;; Code:

(require 'treesit)

(defvar luadoc-ts--keywords
  '("@alias" "@as" "@async" "@cast" "@cast" "@class" "@deprecated" "@diagnostic"
    "@enum" "@field" "@generic" "@language" "@meta" "@module" "@nodiscard"
    "@operator" "@overload" "@package" "@param" "@return"
    "@see" "@source" "@type" "@vararg" "@version"
    "extends")
  "Keywords for tree-sitter font-locking.")

(defvar luadoc-ts-font-lock-rules
  (treesit-font-lock-rules
   :language 'luadoc
   :feature 'comment
   '((comment) @font-lock-comment-face

     (at_comment
      (identifier) @font-lock-preprocessor-face
      (_) @font-lock-comment-face)

     (class_at_comment
      (identifier) @font-lock-preprocessor-face
      ("extends" (identifier) @font-lock-type-face) :?
      (_) @font-lock-comment-face :?))

   :language 'luadoc
   :feature 'string
   '([(string) (literal_type) "`"] @font-lock-string-face

     (module_annotation
      (string) @font-lock-string-face))

   :language 'luadoc
   :override t
   :feature 'keyword
   `([,@luadoc-ts--keywords (diagnostic_identifier)] @font-lock-keyword-face

     ["..." "self"] @font-lock-builtin-face

     (language_injection
      "@language" (identifier) @font-lock-keyword-face)

     ;; Macro
     (alias_annotation
      (identifier) @font-lock-function-name-face)

     (version_annotation
      version: _ @font-lock-builtin-face)

     (source_annotation
      filename: (identifier) @font-lock-constant-face
      extension: (identifier) @font-lock-constant-face)

     (param_annotation
      (identifier) @font-lock-variable-name-face)

     (parameter
      (identifier) @font-lock-variable-name-face)

     (field_annotation
      (identifier) @font-lock-property-name-face))

   :language 'luadoc
   :feature 'property
   '((table_literal_type
      field: (identifier) @font-lock-property-name-face)

     (member_type ["#" "."] :anchor (identifier) @font-lock-variable-name-face)

     (member_type (identifier) @font-lock-type-face))

   :language 'luadoc
   :feature 'type
   '(["fun" "function"] @font-lock-type-face

     ;; Qualifiers
     ["public" "protected" "private" "package" "@public" "@protected"
      "@private" "(exact)" "(key)"]
     @font-lock-preprocessor-face

     (table_type
      "table" @font-lock-builtin-face)

     (builtin_type) @font-lock-builtin-face

     (generic_annotation
      (identifier) @font-lock-type-face)

     (class_annotation
      (identifier) @font-lock-type-face)

     (enum_annotation
      (identifier) @font-lock-type-face)

     (array_type) @font-lock-type-face
     ;; (array_type ["[" "]"] @font-lock-type-face)

     (type) @font-lock-type-face)

   :language 'luadoc
   :feature 'number
   '([(number) (numeric_literal_type)] @font-lock-number-face)

   :language 'luadoc
   :feature 'bracket
   '(["[" "]" "[[" "]]" "[=[" "]=]" "{" "}" "(" ")" "<" ">"]
     @font-lock-bracket-face)

   :language 'luadoc
   :feature 'delimiter
   '([ "," "." "#" ":" ] @font-lock-delimiter-face)

   :language 'luadoc
   :feature 'operator
   '(["|" "+" "-"] @font-lock-operator-face

     ["@" "?"] @font-lock-misc-punctuation-face)

   :language 'luadoc
   :feature 'variable
   '((identifier) @font-lock-variable-name-face)

   :language 'lua
   :feature 'comment
   :override 'keep
   '(((comment) @font-lock-doc-face
      (:match "\\`---" @font-lock-doc-face))
     (comment
      start: _ @font-lock-comment-delimiter-face
      content: _ @font-lock-comment-face)
     (hash_bang_line) @nvp-treesit-fontify-hash-bang))
  "Tree-sitter font-locking rules for Luadocs.")

(defvar luadoc-ts-font-lock-feature-list
  '(( comment)
    ( keyword type string)
    ( property number)
    ( bracket delimiter operator variable)))


;;; Embedding in Lua

(defvar lua-ts--treesit-luadoc-beginning-regexp (rx bos (* "-") (* white) "@")
  "Regular expression matching the beginning of a luadoc block comment.")

(defun lua-ts-language-at-point (point)
  "Return the language at POINT."
  (let ((node (treesit-node-at point 'lua)))
    (if (and (treesit-ready-p 'luadoc t)
             (equal (treesit-node-type node) "comment_content")
             (string-match-p
              lua-ts--treesit-luadoc-beginning-regexp
              (treesit-node-text node)))
        'luadoc
      'lua)))

;; (defun luadoc-ts--treesit-language-at-point (point)
;;   (let ((node (treesit-node-at point 'lua)))
;;     (if (and (equal "comment_content" (treesit-node-type node))
;;              (>= point (1+ (treesit-node-start node)))
;;              ;; (< point (treesit-node-end node))
;;              )
;;         'luadoc
;;       'lua)))

;; (defvar luadoc-ts--range-query
;;   (when (treesit-available-p)
;;     (treesit-query-compile
;;      'lua
;;      `((comment
;;         start: "--"
;;         content: ((_) @luadoc
;;                   (:match ,(rx bos "-" (* space) (or "@" "|")) @luadoc)))))))

;; (defun luadoc-ts--update-ranges (&optional beg end)
;;   ())
;;; FIXME(4/26/24): treesit still has issues with
;; (defvar luadoc-ts--treesit-range-rules
;;   (treesit-range-rules
;;    :host 'lua
;;    :embed 'luadoc
;;    ;; :local t
;;    :offset '(1 . 0)
;;    luadoc-ts--range-query))

(defun luadoc-ts--merge-features (a b)
  "Merge `treesit-font-lock-feature-list's A with B."
  (cl-loop for x in a
           for y in b
           collect (seq-uniq (append x y))))

;;;###autoload
(defun luadoc-ts-enable ()
  (interactive)
  ;; (treesit-parser-create 'luadoc)
  (when (treesit-ready-p 'luadoc t)
    (when (treesit-ready-p 'luadoc t)
      (setq-local treesit-range-settings
                  (treesit-range-rules
                   :embed 'luadoc
                   :host 'lua
                   :offset '(1 . 0)
                   `(((comment_content) @capture
                      (:match ,lua-ts--treesit-luadoc-beginning-regexp @capture))))))

    (setq-local treesit-language-at-point-function #'lua-ts-language-at-point)

    (setq-local treesit-font-lock-settings
                (seq-uniq
                 (append treesit-font-lock-settings luadoc-ts-font-lock-rules)
                 #'equal))

    (setq-local treesit-font-lock-feature-list
                (luadoc-ts--merge-features
                 treesit-font-lock-feature-list
                 luadoc-ts-font-lock-feature-list))

    (treesit-font-lock-recompute-features)))

;;;###autoload
(define-derived-mode luadoc-ts-mode prog-mode "Luadoc"
  "Major mode for testing Luadoc expressions."
  :group 'luadoc
  (when (treesit-ready-p 'luadoc)
    (treesit-parser-create 'luadoc)
    (setq-local treesit-font-lock-settings luadoc-ts-font-lock-rules)
    (setq-local treesit-font-lock-feature-list luadoc-ts-font-lock-feature-list)
    (treesit-major-mode-setup)))

(provide 'luadoc-ts)
;; Local Variables:
;; coding: utf-8
;; indent-tabs-mode: nil
;; End:
;;; luadoc-ts.el ends here
