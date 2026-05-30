creation du fichier .qip avec l'interface de quartus
remplacement du tableau par l'instant irom_inst 
Error (12006): Node instance "irom_inst" instantiates undefined entity "irom". Ensure that required library paths are specified correctly, define the specified entity, or change the instantiation. If this entity represents Intel FPGA or third-party IP, generate the synthesis files for the IP.
il faut ajouter dans device pins option configuration pour l'initiation
et le chemin dans verilog vers les megafunction 
/opt/intelFPGA_lite/23.1std/quartus/libraries/megafunctions
possiblement la premiere configuration pourrait suffire (sans remplacer le 
tableau par l'instance, à tester... 
suppression de l'instance de la rom. Retour à un tableau 
compilation ok. synthese ok. 
Le code ne s'effectue pas en continu. [D[D
hypothese confusion sur dmem et imem et écriture dans imem 
en réponse, deplacement des données en mémoire apres l'adresse 0x200
modification du tb pour afficher les instructions "en clair" 
inversion du reset (actif low) 
ajout d'un diviseur d'horloge 2²20 et d'un affichage du PC
test en sythese : ok. 
Reste à convertir en VHDL 
ajout des version VHDL : V1 (pour ghdl) et V2 (pour modelsim)
simulation et synthese ok. La version ghdl ne montre pas les transferts reg-mem
du fait de l'impossibilité de descendre dans les signaux d'une instance
ajout d'une soustraction (uniquement type R) et de son test (source asm). 
test SUB (r) dans verilog + tb : ok
