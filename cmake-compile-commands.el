;;; cmake-compile-commands.el --- compile_commands.json analyser

;; Copyright (C) 2016 William Xu

;; Authors: William Xu <william.xwl@gmail.com>

;; URL: https://github.com/xwl/cmake-compile-commands
;; Version: 0.1
;; Package-Requires: ((projectile "0.13.0-cvs") (seq "1.11"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; For a cmake project, compile_commands.json contains exact command
;; line compile command for each source file in the project.  The
;; package analyses compile_commands.json and provides easy access to
;; compiler command, compile args, compile includes, etc.  Other tools
;; like flycheck or auto-complete-clang.el then can use this lib to
;; support cmake projects easily.
;;
;; compile_commands.json can be generated via below cmake command:
;;         cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=1

;;; Code:

(require 'json)
(require 'tramp)

(require 'projectile)
(require 'seq)

(defcustom cmake-compile-commands-build-directories '()
  "List of build directories containing compile_commands.json.
compile_commands.json file can created by:

    cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=1"
  :group 'auto-complete
  :type 'list)

;; ((root . parsed-js)...)
(defvar cmake-compile-commands-json-cache '())

(defun cmake-compile-commands-project-root ()
  (let ((projectile-require-project-root nil))
    (projectile-project-root)))

(defun cmake-compile-commands-full-args ()
  "Complete command line."
  (let* ((root (cmake-compile-commands-project-root))
         (js-data (assoc root cmake-compile-commands-json-cache)))
    (if js-data
        (setq js-data (cdr js-data))
      (let ((json-file (concat (cl-find-if (lambda (f) (string-match-p root f))
                                           cmake-compile-commands-build-directories)
                               "/compile_commands.json")))
        (unless (file-exists-p json-file)
          (error "compile_commands.json not found, check `cmake-compile-commands-build-directories'"))
        (setq js-data (json-read-file json-file))
        (setq cmake-compile-commands-json-cache (cons (cons root js-data) cmake-compile-commands-json-cache))))

    (when js-data
      (let* ((file (file-truename
                    (let ((f (buffer-file-name)))
                      (if (tramp-tramp-file-p f)
                          (with-parsed-tramp-file-name f v v-localname)
                        f))))

             (matched-entry (seq-find (lambda (entry) (equal (cdr (assq 'file entry)) file))
                                      js-data))

             (cmd (cdr (assq 'command matched-entry))))
        (split-string cmd)))))

(defun cmake-compile-commands-args-excluding-output ()
  "Compile options excluding options after -o."
  (seq-take-while (lambda (el) (not (equal el "-o")))
                  (cmake-compile-commands-full-args)))

(defun cmake-compile-commands-args ()
  "Compile options excluding compiler and options after -o."
  (cdr (cmake-compile-commands-args-excluding-output)))

(defun cmake-compile-commands-includes ()
  "Command line include paths list."
  (let ((lst (cmake-compile-commands-args))
        (includes '()))
    (let ((case-fold-search nil)
          el)
      (while lst
        (setq el (car lst))
        (cond ((string-match-p "-I\\|--sysroot=" el)
               (setq includes (cons el includes)))
              ((string= "-isystem" el)
               (setq includes (cons el includes))
               (setq lst (cdr lst))
               (setq includes (cons (car lst) includes))))
        (setq lst (cdr lst)))
      (reverse includes))))

(defun cmake-compile-commands-compiler ()
  "Compiler executable."
  (car (cmake-compile-commands-full-args)))

(defun cmake-compile-commands-source ()
  "Source cpp."
  (car (last (cmake-compile-commands-full-args))))

(defun cmake-compile-commands-source-directory ()
  "Directory of source cpp."
  (file-name-directory (cmake-compile-commands-source)))

(provide 'cmake-compile-commands)
;;; cmake-compile-commands.el ends here
