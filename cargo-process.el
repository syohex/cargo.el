;;; cargo-process.el --- Cargo Process Major Mode

;; Copyright (C) 2015  Kevin W. van Rooijen

;; Author: Kevin W. van Rooijen <kevin.van.rooijen@attichacker.com>
;; Keywords: processes, tools

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

;; Cargo Process Major mode.
;; Used to run Cargo background processes.
;; Current supported Cargo functions:
;;  * cargo-process-bench  - Run the benchmarks.
;;  * cargo-process-build  - Compile the current project.
;;  * cargo-process-clean  - Remove the target directory.
;;  * cargo-process-doc    - Build this project's and its dependencies' documentation.
;;  * cargo-process-new    - Create a new cargo project.
;;  * cargo-process-run    - Build and execute src/main.rs.
;;  * cargo-process-search - Search registry for crates.
;;  * cargo-process-test   - Run the tests.
;;  * cargo-process-update - Update dependencies listed in Cargo.lock.
;;
;;; Code:

(require 'cl-lib)

(defgroup cargo-process nil
  "Cargo Process group."
  :prefix "cargo-process-"
  :group 'cargo)

(defvar cargo-process-mode-hook nil)
(defvar cargo-process-mode-map nil "Keymap for Cargo major mode.")

(defface cargo-process--error-face
  '((t (:foreground "#FF0000")))
  "Error face"
  :group 'cargo-process)

(defface cargo-process--warning-face
  '((t (:foreground "#eeee00")))
  "Warning face"
  :group 'cargo-process)

(defconst cargo-process-font-lock-keywords
  '(("error" . 'cargo-process--error-face)
    ("warning" . 'cargo-process--warning-face))
  "Minimal highlighting expressions for cargo-process mode.")

(define-derived-mode cargo-process-mode fundamental-mode "Cargo-Process."
  "Major mode for the Cargo process buffer."
  (use-local-map cargo-process-mode-map)
  (setq major-mode 'cargo-process-mode)
  (setq mode-name "Cargo-Process")
  ;; FIXME Why does the process not display full buffer when these are set to 10000 and 1?
  (setq-local scroll-conservatively 0) ;; 10000
  (setq-local scroll-step 0) ;; 1
  (setq-local truncate-lines t)
  (read-only-mode t)
  (run-hooks 'cargo-process-mode-hook)
  (font-lock-add-keywords nil cargo-process-font-lock-keywords))

(defun cargo-process--finished-sentinel (process event)
  "Execute after PROCESS return and EVENT is 'finished'."
  (when (equal event "finished\n")
    (with-current-buffer (process-buffer process)
      (setq mode-name "Cargo-Process:no process"))
    (message "Cargo Process finished.")))

(defun cargo-process--cleanup (buffer)
  "Clean up the old Cargo process BUFFER when a similar process is run."
  (when (get-buffer-process buffer)
    (stop-process buffer))
  (when (get-buffer buffer)
    (with-current-buffer buffer
      (read-only-mode -1)
      (erase-buffer))))

(defun cargo-process--activate-mode (buffer)
  "Execute commands BUFFER at process start."
  (with-current-buffer buffer
    (funcall 'cargo-process-mode)
    (setq-local window-point-insertion-type t)))

(cl-defun cargo-process--start (name command-args &key hidden)
  "Starts the Cargo process NAME with the cargo arguments COMMAND-ARGS.
If the HIDDEN keyword is not nil then the buffer won't be shown."
  (let* ((buffer-name (concat "*Cargo " name "*"))
         (buffer (get-buffer-create buffer-name))
         (process-args (concat "cargo " command-args)))
    (cargo-process--cleanup buffer-name)
    (start-process-shell-command buffer-name buffer process-args)
    (cargo-process--activate-mode buffer)
    (with-current-buffer buffer
      (setq mode-name "Cargo-Process:run"))
    (set-process-sentinel (get-buffer-process buffer-name) 'cargo-process--finished-sentinel)
    (unless hidden
      (display-buffer buffer-name))))

;;;###autoload
(defun cargo-process-bench ()
  "Run the Cargo bench command.
Cargo: Run the benchmarks."
  (interactive)
  (cargo-process--start "Bench" "bench"))

;;;###autoload
(defun cargo-process-build ()
  "Run the Cargo build command.
Cargo: Compile the current project."
  (interactive)
  (cargo-process--start "Build" "build"))

;;;###autoload
(defun cargo-process-clean ()
  "Run the Cargo clean command.
Cargo: Remove the target directory."
  (interactive)
  (cargo-process--start "Clean" "clean" :hidden t))

;;;###autoload
(defun cargo-process-doc ()
  "Run the Cargo doc command.
Cargo: Build this project's and its dependencies' documentation."
  (interactive)
  (cargo-process--start "Doc" "doc"))

;;;###autoload
(defun cargo-process-new (name &optional bin)
  "Run the Cargo new command.
Cargo: Create a new cargo project.
NAME is the name of your application.
If BIN is t then create a binary application, otherwise a library."
  (interactive "sProject Name: ")
  (let* ((bin (when (or bin (y-or-n-p "Create Bin Project?")) "--bin"))
         (command (concat "new " name " " bin)))
    (cargo-process--start "New" command :hidden t)))

;;;###autoload
(defun cargo-process-run ()
  "Run the Cargo run command.
Cargo: Build and execute src/main.rs."
  (interactive)
  (cargo-process--start "Run" "run"))

;;;###autoload
(defun cargo-process-search (search-term)
  "Run the Cargo search command.
Cargo: Search registry for crates.
SEARCH-TERM is used as the search term for the Cargo registry."
  (interactive "sSearch: ")
  (cargo-process--start "Search" (format "search %s" search-term)))

;;;###autoload
(defun cargo-process-test ()
  "Run the Cargo test command.
Cargo: Run the tests."
  (interactive)
  (cargo-process--start "Test" "test"))

;;;###autoload
(defun cargo-process-update ()
  "Run the Cargo update command.
Cargo: Update dependencies listed in Cargo.lock."
  (interactive)
  (cargo-process--start "Update" "update"))

(provide 'cargo-process)
;;; cargo-process.el ends here
