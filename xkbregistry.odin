package xkbcommon

import "core:c"

foreign import lib "system:xkbcommon"
_ :: lib

/**
* @struct rxkb_context
*
* Opaque top level library context object.
*
* The context contains general library state, like include paths and parsed
* data. Objects are created in a specific context, and multiple contexts
* may coexist simultaneously. Objects from different contexts are
* completely separated and do not share any memory or state.
*/
Rxkb_Context :: struct {}

/**
* @struct rxkb_model
*
* Opaque struct representing an XKB model.
*/
Rxkb_Model :: struct {}

/**
* @struct rxkb_layout
*
* Opaque struct representing an XKB layout, including an optional variant.
* Where the variant is `NULL`, the layout is the base layout.
*
* For example, `us` is the base layout, `us(intl)` is the `intl` variant of the
* layout `us`.
*/
Rxkb_Layout :: struct {}

/**
* @struct rxkb_option_group
*
* Opaque struct representing an option group. Option groups divide the
* individual options into logical groups. Their main purpose is to indicate
* whether some options are mutually exclusive or not.
*/
Rxkb_Option_Group :: struct {}

/**
* @struct rxkb_option
*
* Opaque struct representing an XKB option. Options are grouped inside an @ref
* rxkb_option_group.
*/
Rxkb_Option :: struct {}

/**
*
* @struct rxkb_iso639_code
*
* Opaque struct representing an ISO 639-3 code (e.g. `eng`, `fra`). There
* is no guarantee that two identical ISO codes share the same struct. You
* must not rely on the pointer value of this struct.
*
* See https://iso639-3.sil.org/code_tables/639/data for a list of codes.
*/
Rxkb_Iso639_Code :: struct {}

/**
*
* @struct rxkb_iso3166_code
*
* Opaque struct representing an ISO 3166 Alpha 2 code (e.g. `US`, `FR`).
* There is no guarantee that two identical ISO codes share the same struct.
* You must not rely on the pointer value of this struct.
*
* See https://en.wikipedia.org/wiki/List_of_ISO_3166_country_codes for a list
* of codes.
*/
Rxkb_Iso3166_Code :: struct {}

/**
* Describes the popularity of an item. Historically, some highly specialized or
* experimental definitions are excluded from the default list and shipped in
* separate files. If these extra definitions are loaded (see @ref
* RXKB_CONTEXT_LOAD_EXOTIC_RULES), the popularity of the item is set
* accordingly.
*
* If the exotic items are not loaded, all items will have the standard
* popularity.
*/
Rxkb_Popularity :: enum u32 {
	STANDARD = 1,
	EXOTIC   = 2,
}

/**
* Flags for context creation.
*/
Rxkb_Context_Flags :: enum u32 {
	NO_FLAGS            = 0,

	/**
	* Skip the default include paths. This requires the caller to call
	* `rxkb_context_include_path_append()` or
	* `rxkb_context_include_path_append_default()`.
	*/
	NO_DEFAULT_INCLUDES = 1,

	/**
	* Load the extra items that are considered too exotic for the default list.
	*
	* For historical reasons, xkeyboard-config ships those exotic rules in a
	* separate file (e.g. `evdev.extras.xml`). Where the exotic rules are
	* requested, libxkbregistry will look for and load `$ruleset.extras.xml`
	* in the include paths, see `rxkb_context_include_path_append()` for
	* details on the lookup behavior.
	*/
	LOAD_EXOTIC_RULES   = 2,

	/**
	* Disable the use of `secure_getenv()` for this context, so that privileged
	* processes can use environment variables. Client uses at their own risk.
	*
	* @since 1.5.0
	*/
	NO_SECURE_GETENV    = 4,
}

@(default_calling_convention="c", link_prefix="xkb_")
foreign lib {
	/**
	* Create a new xkb registry context.
	*
	* The context has an initial refcount of 1. Use `rxkb_context_unref()` to
	* release memory associated with this context.
	*
	* Creating a context does not parse the files yet, use
	* `rxkb_context_parse()`.
	*
	* @param flags Flags affecting context behavior
	* @return A new xkb registry context or `NULL` on failure
	*/
	rxkb_context_new :: proc(flags: Rxkb_Context_Flags) -> ^Rxkb_Context ---
}

/** Specifies a logging level. */
Rxkb_Log_Level :: enum u32 {
	CRITICAL = 10, /**< Log critical internal errors only. */
	ERROR    = 20, /**< Log all errors. */
	WARNING  = 30, /**< Log warnings and errors. */
	INFO     = 40, /**< Log information, warnings, and errors. */
	DEBUG    = 50, /**< Log everything. */
}

@(default_calling_convention="c", link_prefix="xkb_")
foreign lib {
	/**
	* Set the current logging level.
	*
	* @param ctx     The context in which to set the logging level.
	* @param level   The logging level to use.  Only messages from this level
	* and below will be logged.
	*
	* The default level is `::RXKB_LOG_LEVEL_ERROR`.  The environment variable
	* `RXKB_LOG_LEVEL`, if set at the time the context was created, overrides the
	* default value.  It may be specified as a level number or name.
	*/
	rxkb_context_set_log_level :: proc(ctx: ^Rxkb_Context, level: Rxkb_Log_Level) ---

	/**
	* Get the current logging level.
	*/
	rxkb_context_get_log_level :: proc(ctx: ^Rxkb_Context) -> Rxkb_Log_Level ---

	/**
	* Set a custom function to handle logging messages.
	*
	* @param ctx     The context in which to use the set logging function.
	* @param log_fn  The function that will be called for logging messages.
	* Passing `NULL` restores the default function, which logs to `stderr`.
	*
	* By default, log messages from this library are printed to stderr.  This
	* function allows you to replace the default behavior with a custom
	* handler.  The handler is only called with messages which match the
	* current logging level and verbosity settings for the context.
	* level is the logging level of the message.  @a format and @a args are
	* the same as in the `vprintf(3)` function.
	*
	* You may use `rxkb_context_set_user_data()` on the context, and then call
	* `rxkb_context_get_user_data()` from within the logging function to provide
	* it with additional private context.
	*/
	rxkb_context_set_log_fn :: proc(ctx: ^Rxkb_Context, log_fn: proc "c" (ctx: ^Rxkb_Context, level: Rxkb_Log_Level, format: cstring, args: c.va_list)) ---

	/**
	* Parse the given ruleset. This can only be called once per context and once
	* parsed the data in the context is considered constant and will never
	* change.
	*
	* This function parses all files with the given ruleset name. See
	* rxkb_context_include_path_append() for details.
	*
	* If this function returns false, libxkbregistry failed to parse the xml files.
	* This is usually caused by invalid files on the host and should be debugged by
	* the host’s administrator using external tools. Callers should reduce the
	* include paths to known good paths and/or fall back to a default RMLVO set.
	*
	* If this function returns false, the context should be be considered dead and
	* must be released with `rxkb_context_unref()`.
	*
	* @param ctx The xkb registry context
	* @param ruleset The ruleset to parse, e.g. `evdev`
	* @return `true` on success or `false` on failure
	*/
	rxkb_context_parse :: proc(ctx: ^Rxkb_Context, ruleset: cstring) -> bool ---

	/**
	* Parse the default ruleset as configured at build time. See
	* `rxkb_context_parse()` for details.
	*/
	rxkb_context_parse_default_ruleset :: proc(ctx: ^Rxkb_Context) -> bool ---

	/**
	* Increases the refcount of this object by one and returns the object.
	*
	* @param ctx The xkb registry context
	* @return The passed in object
	*/
	rxkb_context_ref :: proc(ctx: ^Rxkb_Context) -> ^Rxkb_Context ---

	/**
	* Decreases the refcount of this object by one. Where the refcount of an
	* object hits zero, associated resources will be freed.
	*
	* @param ctx The xkb registry context
	* @return always `NULL`
	*/
	rxkb_context_unref :: proc(ctx: ^Rxkb_Context) -> ^Rxkb_Context ---

	/**
	* Assign user-specific data. libxkbregistry will not look at or modify the
	* data, it will merely return the same pointer in
	* `rxkb_context_get_user_data()`.
	*
	* @param ctx The xkb registry context
	* @param user_data User-specific data pointer
	*/
	rxkb_context_set_user_data :: proc(ctx: ^Rxkb_Context, user_data: rawptr) ---

	/**
	* Return the pointer passed into `rxkb_context_get_user_data()`.
	*
	* @param ctx The xkb registry context
	* @return User-specific data pointer
	*/
	rxkb_context_get_user_data :: proc(ctx: ^Rxkb_Context) -> rawptr ---

	/**
	* Append a new entry to the context’s include path.
	*
	* The include path handling is optimized for the most common use-case: a set of
	* system files that provide a complete set of MLVO and some
	* custom MLVO provided by a user **in addition** to the system set.
	*
	* The include paths should be given so that the least complete path is
	* specified first and the most complete path is appended last. For example:
	*
	* ```c
	* ctx = rxkb_context_new(RXKB_CONTEXT_NO_DEFAULT_INCLUDES);
	* rxkb_context_include_path_append(ctx, `/home/user/.config/xkb`);
	* rxkb_context_include_path_append(ctx, `/usr/share/X11/xkb`);
	* rxkb_context_parse(ctx, `evdev`);
	* ```
	*
	* The above example reflects the default behavior unless @ref
	* RXKB_CONTEXT_NO_DEFAULT_INCLUDES is provided.
	*
	* Loading of the files is in **reverse order**, i.e. the last path appended is
	* loaded first - in this case the ``/usr/share/X11/xkb`` path.
	* Any models, layouts, variants and options defined in the `evdev` ruleset
	* are loaded into the context. Then, any RMLVO found in the `evdev` ruleset of
	* the user’s path (``/home/user/.config/xkb`` in this example) are **appended**
	* to the existing set.
	*
	* Note that data from previously loaded include paths is never overwritten,
	* only appended to. It is not not possible to change the system-provided data,
	* only to append new models, layouts, variants and options to it.
	*
	* In other words, to define a new variant of the `us` layout called `banana`,
	* the following XML is sufficient.
	*
	* ```xml
	* <xkbConfigRegistry version="1.1">
	* <layoutList>
	*   <layout>
	*     <configItem>
	*       <name>us</name>
	*     </configItem>
	*     <variantList>
	*       <variant>
	*         <configItem>
	*          <name>banana</name>
	*          <description>English (Banana)</description>
	*        </configItem>
	*      </variant>
	*    </layout>
	* </layoutList>
	* </xkbConfigRegistry>
	* ```
	*
	* The list of models, options and all other layouts (including `us` and its
	* variants) is taken from the system files. The resulting list of layouts will
	* thus have a `us` keyboard layout with the variant `banana` and all other
	* system-provided variants (`dvorak`, `colemak`, `intl`, etc.)
	*
	* This function must be called before `rxkb_context_parse()` or
	* `rxkb_context_parse_default_ruleset()`.
	*
	* @returns `true` on success, or `false` if the include path could not be added
	* or is inaccessible.
	*/
	rxkb_context_include_path_append :: proc(ctx: ^Rxkb_Context, path: cstring) -> bool ---

	/**
	* Append the default include paths to the context’s include path.
	* See `rxkb_context_include_path_append()` for details about the merge order.
	*
	* This function must be called before `rxkb_context_parse()` or
	* `rxkb_context_parse_default_ruleset()`.
	*
	* @returns `true` on success, or `false` if the include path could not be added
	* or is inaccessible.
	*/
	rxkb_context_include_path_append_default :: proc(ctx: ^Rxkb_Context) -> bool ---

	/**
	* Return the first model for this context. Use this to start iterating over
	* the models, followed by calls to `rxkb_model_next()`. Models are not sorted.
	*
	* The refcount of the returned model is not increased. Use `rxkb_model_ref()`
	* if you need to keep this struct outside the immediate scope.
	*
	* @return The first model in the model list.
	*/
	rxkb_model_first :: proc(ctx: ^Rxkb_Context) -> ^Rxkb_Model ---

	/**
	* Return the next model for this context. Returns `NULL` when no more models
	* are available.
	*
	* The refcount of the returned model is not increased. Use `rxkb_model_ref()`
	* if you need to keep this struct outside the immediate scope.
	*
	* @return the next model or `NULL` at the end of the list
	*/
	rxkb_model_next :: proc(m: ^Rxkb_Model) -> ^Rxkb_Model ---

	/**
	* Increase the refcount of the argument by one.
	*
	* @returns The argument passed in to this function.
	*/
	rxkb_model_ref :: proc(m: ^Rxkb_Model) -> ^Rxkb_Model ---

	/**
	* Decrease the refcount of the argument by one. When the refcount hits zero,
	* all memory associated with this struct is freed.
	*
	* @returns always `NULL`
	*/
	rxkb_model_unref :: proc(m: ^Rxkb_Model) -> ^Rxkb_Model ---

	/**
	* Return the name of this model. This is the value for M in RMLVO, to be used
	* with libxkbcommon.
	*/
	rxkb_model_get_name :: proc(m: ^Rxkb_Model) -> cstring ---

	/**
	* Return a human-readable description of this model. This function may return
	* `NULL`.
	*/
	rxkb_model_get_description :: proc(m: ^Rxkb_Model) -> cstring ---

	/**
	* Return the vendor name for this model. This function may return `NULL`.
	*/
	rxkb_model_get_vendor :: proc(m: ^Rxkb_Model) -> cstring ---

	/**
	* Return the popularity for this model.
	*/
	rxkb_model_get_popularity :: proc(m: ^Rxkb_Model) -> Rxkb_Popularity ---

	/**
	* Return the first layout for this context. Use this to start iterating over
	* the layouts, followed by calls to `rxkb_layout_next()`.
	*
	* @note Layouts are not sorted.
	*
	* The refcount of the returned layout is not increased.
	* Use `rxkb_layout_ref()` if you need to keep this struct outside the immediate
	* scope.
	*
	* @return The first layout in the layout list.
	*/
	rxkb_layout_first :: proc(ctx: ^Rxkb_Context) -> ^Rxkb_Layout ---

	/**
	* Return the next layout for this context. Returns `NULL` when no more layouts
	* are available.
	*
	* The refcount of the returned layout is not increased. Use `rxkb_layout_ref()`
	* if you need to keep this struct outside the immediate scope.
	*
	* @return the next layout or `NULL` at the end of the list
	*/
	rxkb_layout_next :: proc(l: ^Rxkb_Layout) -> ^Rxkb_Layout ---

	/**
	* Increase the refcount of the argument by one.
	*
	* @returns The argument passed in to this function.
	*/
	rxkb_layout_ref :: proc(l: ^Rxkb_Layout) -> ^Rxkb_Layout ---

	/**
	* Decrease the refcount of the argument by one. When the refcount hits zero,
	* all memory associated with this struct is freed.
	*
	* @returns always `NULL`
	*/
	rxkb_layout_unref :: proc(l: ^Rxkb_Layout) -> ^Rxkb_Layout ---

	/**
	* Return the name of this layout. This is the value for L in RMLVO, to be used
	* with libxkbcommon.
	*/
	rxkb_layout_get_name :: proc(l: ^Rxkb_Layout) -> cstring ---

	/**
	* Return the variant of this layout. This is the value for V in RMLVO, to be
	* used with libxkbcommon.
	*
	* A variant does not stand on its own, it always depends on the base layout.
	* e.g. there may be multiple variants called `intl` but there is only one
	* `us(intl)`.
	*
	* Where the variant is `NULL`, the layout is the base layout (e.g. `us`).
	*/
	rxkb_layout_get_variant :: proc(l: ^Rxkb_Layout) -> cstring ---

	/**
	* Return a short (one-word) description of this layout. This function may
	* return `NULL`.
	*/
	rxkb_layout_get_brief :: proc(l: ^Rxkb_Layout) -> cstring ---

	/**
	* Return a human-readable description of this layout. This function may return
	* `NULL`.
	*/
	rxkb_layout_get_description :: proc(l: ^Rxkb_Layout) -> cstring ---

	/**
	* Return the popularity for this layout.
	*/
	rxkb_layout_get_popularity :: proc(l: ^Rxkb_Layout) -> Rxkb_Popularity ---

	/**
	* Return the first option group for this context. Use this to start iterating
	* over the option groups, followed by calls to `rxkb_option_group_next()`.
	* Option groups are not sorted.
	*
	* The refcount of the returned option group is not increased. Use
	* `rxkb_option_group_ref()` if you need to keep this struct outside the immediate
	* scope.
	*
	* @return The first option group in the option group list.
	*/
	rxkb_option_group_first :: proc(ctx: ^Rxkb_Context) -> ^Rxkb_Option_Group ---

	/**
	* Return the next option group for this context. Returns `NULL` when no more
	* option groups are available.
	*
	* The refcount of the returned option group is not increased. Use
	* `rxkb_option_group_ref()` if you need to keep this struct outside the immediate
	* scope.
	*
	* @return the next option group or `NULL` at the end of the list
	*/
	rxkb_option_group_next :: proc(g: ^Rxkb_Option_Group) -> ^Rxkb_Option_Group ---

	/**
	* Increase the refcount of the argument by one.
	*
	* @returns The argument passed in to this function.
	*/
	rxkb_option_group_ref :: proc(g: ^Rxkb_Option_Group) -> ^Rxkb_Option_Group ---

	/**
	* Decrease the refcount of the argument by one. When the refcount hits zero,
	* all memory associated with this struct is freed.
	*
	* @returns always `NULL`
	*/
	rxkb_option_group_unref :: proc(g: ^Rxkb_Option_Group) -> ^Rxkb_Option_Group ---

	/**
	* Return the name of this option group. This is **not** the value for O in
	* RMLVO, the name can be used for internal sorting in the caller. This function
	* may return `NULL`.
	*/
	rxkb_option_group_get_name :: proc(m: ^Rxkb_Option_Group) -> cstring ---

	/**
	* Return a human-readable description of this option group. This function may
	* return `NULL`.
	*/
	rxkb_option_group_get_description :: proc(m: ^Rxkb_Option_Group) -> cstring ---

	/**
	* @return `true` if multiple options within this option group can be selected
	*                simultaneously, `false` if all options within this option
	*                group are mutually exclusive.
	*/
	rxkb_option_group_allows_multiple :: proc(g: ^Rxkb_Option_Group) -> bool ---

	/**
	* Return the popularity for this option group.
	*/
	rxkb_option_group_get_popularity :: proc(g: ^Rxkb_Option_Group) -> Rxkb_Popularity ---

	/**
	* Return the first option for this option group. Use this to start iterating
	* over the options, followed by calls to `rxkb_option_next()`. Options are not
	* sorted.
	*
	* The refcount of the returned option is not increased. Use `rxkb_option_ref()`
	* if you need to keep this struct outside the immediate scope.
	*
	* @return The first option in the option list.
	*/
	rxkb_option_first :: proc(group: ^Rxkb_Option_Group) -> ^Rxkb_Option ---

	/**
	* Return the next option for this option group. Returns `NULL` when no more
	* options are available.
	*
	* The refcount of the returned options is not increased. Use `rxkb_option_ref()`
	* if you need to keep this struct outside the immediate scope.
	*
	* @returns The next option or `NULL` at the end of the list
	*/
	rxkb_option_next :: proc(o: ^Rxkb_Option) -> ^Rxkb_Option ---

	/**
	* Increase the refcount of the argument by one.
	*
	* @returns The argument passed in to this function.
	*/
	rxkb_option_ref :: proc(o: ^Rxkb_Option) -> ^Rxkb_Option ---

	/**
	* Decrease the refcount of the argument by one. When the refcount hits zero,
	* all memory associated with this struct is freed.
	*
	* @returns always `NULL`
	*/
	rxkb_option_unref :: proc(o: ^Rxkb_Option) -> ^Rxkb_Option ---

	/**
	* Return the name of this option. This is the value for O in RMLVO, to be used
	* with libxkbcommon.
	*/
	rxkb_option_get_name :: proc(o: ^Rxkb_Option) -> cstring ---

	/**
	* Return a short (one-word) description of this option. This function may
	* return `NULL`.
	*/
	rxkb_option_get_brief :: proc(o: ^Rxkb_Option) -> cstring ---

	/**
	* Return a human-readable description of this option. This function may return
	* `NULL`.
	*/
	rxkb_option_get_description :: proc(o: ^Rxkb_Option) -> cstring ---

	/**
	* Return the popularity for this option.
	*/
	rxkb_option_get_popularity :: proc(o: ^Rxkb_Option) -> Rxkb_Popularity ---

	/**
	* Return `true` if the given option accepts layout index specifiers to restrict
	* its application to the corresponding layouts, `false` otherwise.
	*
	* @sa `xkb_rmlvo_builder::xkb_rmlvo_builder_append_layout()`
	* @sa `xkb_rule_names::options`
	*/
	rxkb_option_is_layout_specific :: proc(o: ^Rxkb_Option) -> bool ---

	/**
	* Increase the refcount of the argument by one.
	*
	* @returns The argument passed in to this function.
	*/
	rxkb_iso639_code_ref :: proc(iso639: ^Rxkb_Iso639_Code) -> ^Rxkb_Iso639_Code ---

	/**
	* Decrease the refcount of the argument by one. When the refcount hits zero,
	* all memory associated with this struct is freed.
	*
	* @returns always `NULL`
	*/
	rxkb_iso639_code_unref :: proc(iso639: ^Rxkb_Iso639_Code) -> ^Rxkb_Iso639_Code ---

	/**
	* Return the ISO 639-3 code for this code. E.g. `eng`, `fra`.
	*/
	rxkb_iso639_code_get_code :: proc(iso639: ^Rxkb_Iso639_Code) -> cstring ---

	/**
	* Return the first ISO 639 for this layout. Use this to start iterating over
	* the codes, followed by calls to `rxkb_iso639_code_next()`. Codes are not
	* sorted.
	*
	* The refcount of the returned code is not increased.
	* Use `rxkb_iso639_code_ref()` if you need to keep this struct outside the
	* immediate scope.
	*
	* @return The first code in the code list.
	*/
	rxkb_layout_get_iso639_first :: proc(layout: ^Rxkb_Layout) -> ^Rxkb_Iso639_Code ---

	/**
	* Return the next code in the list. Returns `NULL` when no more codes
	* are available.
	*
	* The refcount of the returned codes is not increased.
	* Use `rxkb_iso639_code_ref()` if you need to keep this struct outside the
	* immediate scope.
	*
	* @returns The next code or `NULL` at the end of the list
	*/
	rxkb_iso639_code_next :: proc(iso639: ^Rxkb_Iso639_Code) -> ^Rxkb_Iso639_Code ---

	/**
	* Increase the refcount of the argument by one.
	*
	* @returns The argument passed in to this function.
	*/
	rxkb_iso3166_code_ref :: proc(iso3166: ^Rxkb_Iso3166_Code) -> ^Rxkb_Iso3166_Code ---

	/**
	* Decrease the refcount of the argument by one. When the refcount hits zero,
	* all memory associated with this struct is freed.
	*
	* @returns always `NULL`
	*/
	rxkb_iso3166_code_unref :: proc(iso3166: ^Rxkb_Iso3166_Code) -> ^Rxkb_Iso3166_Code ---

	/**
	* Return the ISO 3166 Alpha 2 code for this code (e.g. `US`, `FR`).
	*/
	rxkb_iso3166_code_get_code :: proc(iso3166: ^Rxkb_Iso3166_Code) -> cstring ---

	/**
	* Return the first ISO 3166 for this layout. Use this to start iterating over
	* the codes, followed by calls to `rxkb_iso3166_code_next()`. Codes are not
	* sorted.
	*
	* The refcount of the returned code is not increased. Use
	* `rxkb_iso3166_code_ref()` if you need to keep this struct outside the immediate
	* scope.
	*
	* @return The first code in the code list.
	*/
	rxkb_layout_get_iso3166_first :: proc(layout: ^Rxkb_Layout) -> ^Rxkb_Iso3166_Code ---

	/**
	* Return the next code in the list. Returns `NULL` when no more codes
	* are available.
	*
	* The refcount of the returned codes is not increased. Use
	* `rxkb_iso3166_code_ref()` if you need to keep this struct outside the immediate
	* scope.
	*
	* @returns The next code or `NULL` at the end of the list
	*/
	rxkb_iso3166_code_next :: proc(iso3166: ^Rxkb_Iso3166_Code) -> ^Rxkb_Iso3166_Code ---
}

