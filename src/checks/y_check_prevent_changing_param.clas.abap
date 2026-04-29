class Y_CHECK_PREVENT_CHANGING_PARAM definition
  public
  inheriting from Y_CHECK_BASE
  create public .

public section.

  methods CONSTRUCTOR .
  PROTECTED SECTION.
    METHODS inspect_tokens REDEFINITION.

  PRIVATE SECTION.
    METHODS has_at_least_one_changing IMPORTING statement TYPE sstmnt
                                   RETURNING VALUE(result) TYPE abap_bool.

    METHODS is_exception_case IMPORTING position TYPE sy-tabix
                              RETURNING VALUE(result) TYPE abap_bool.

ENDCLASS.



CLASS Y_CHECK_PREVENT_CHANGING_PARAM IMPLEMENTATION.


  METHOD CONSTRUCTOR.
    super->constructor( ).

    settings-pseudo_comment = '"#EC PREVENT_CHANGE' ##NO_TEXT.
    settings-disable_threshold_selection = abap_true.
    settings-threshold = 0.
    settings-documentation = |{ c_docs_path-checks }prefer-returning-to-exporting.md|.

    relevant_statement_types = VALUE #( ( scan_struc_stmnt_type-class_definition )
                                        ( scan_struc_stmnt_type-interface ) ).

    set_check_message( 'Prevent CHANGING parameter!' ).
  ENDMETHOD.


  METHOD has_at_least_one_changing.
    DATA(skip) = abap_false.
    DATA(count) = 0.

    LOOP AT ref_scan->tokens ASSIGNING FIELD-SYMBOL(<token>)
    FROM statement-from
    TO statement-to.

      IF <token>-str = 'IMPORTING'
      OR <token>-str = 'EXPORTING'
      OR <token>-str = 'RETURNING'
      OR <token>-str = 'RAISING'.
        skip = abap_true.
        CLEAR count.
      ELSEIF <token>-str = 'CHANGING'.
        skip = abap_false.
      ENDIF.

      IF skip = abap_true.
        CONTINUE.
      ENDIF.

      DATA(is_declaration) = xsdbool(    <token>-str = 'TYPE'
                                      OR <token>-str = 'LIKE' ).

      IF is_declaration = abap_true
      AND is_exception_case( sy-tabix ) = abap_false.
        count = count + 1.
      ENDIF.

    ENDLOOP.

    result = xsdbool( count = 1 ).
  ENDMETHOD.


  METHOD INSPECT_TOKENS.
    CHECK get_token_abs( statement-from ) = 'METHODS'
    OR get_token_abs( statement-from ) = 'CLASS-METHODS'.

    CHECK has_at_least_one_changing( statement ).

    DATA(check_configuration) = detect_check_configuration( statement ).

    raise_error( statement_level = statement-level
                 statement_index = index
                 statement_from = statement-from
                 check_configuration = check_configuration ).
  ENDMETHOD.


  METHOD is_exception_case.
    TRY.
        DATA(one_ahead) = ref_scan->tokens[ position + 1 ]-str.
        DATA(two_ahead) = ref_scan->tokens[ position + 2 ]-str.

        result = xsdbool(     one_ahead = 'STANDARD'
                          AND two_ahead = 'TABLE' ).

      CATCH cx_sy_itab_line_not_found.
        RETURN.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
