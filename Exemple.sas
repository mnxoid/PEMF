/* Pour utiliser les macros il faut copier le code suivant au début du script (décommenter avec <Ctrl>+<Shift>+</>): */

/* Ce code sert à utiliser des macros en mode execution paralele */
/* Debut d'initialisation */
options mstored sasmstore=TEMP;
%load_stored_functions;
options nomstored;
%SYSMSTORECLEAR;
%load_macros(TEMP.MACRO);
/* Fin d'initialisation */




/* Maintenant on peut faire ce qu'on veut, toutes les variables et fonctions sont accessibles */
/* Par exemple on va mettre des noms de colonnes de TEMP.MACROS dans une macro variable: */
%get_vars(TEMP, MACROS, var_list);
%put &var_list.;