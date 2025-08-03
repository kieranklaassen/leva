import { application } from "./application";

// Explicitly register Stimulus controllers for bundler builds
import CollapsibleController from "./collapsible_controller";
import ClipboardController from "./clipboard_controller";
import PromptAutosaveController from "./prompt_autosave_controller";
import DialogController from "./dialog_controller";
import PromptSelectorController from "./prompt_selector_controller";
import PromptFormController from "./prompt_form_controller";
import PromptSelectorNewController from "./prompt_selector_new_controller";
import PromptFormAutosaveController from "./prompt_form_autosave_controller";
import ButtonLoaderController from "./button_loader_controller";

application.register("collapsible", CollapsibleController);
application.register("clipboard", ClipboardController);
application.register("prompt-autosave", PromptAutosaveController);
application.register("dialog", DialogController);
application.register("prompt-selector", PromptSelectorController);
application.register("prompt-form", PromptFormController);
application.register("prompt-selector-new", PromptSelectorNewController);
application.register("prompt-form-autosave", PromptFormAutosaveController);
application.register("button-loader", ButtonLoaderController);
