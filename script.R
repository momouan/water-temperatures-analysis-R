library(lubridate)
library(questionr)
library(data.table)
library(dplyr)
library(tidyverse)
library(fastICA)
library(FactoMineR)
library(factoextra)
library(EnvStats)


#----------------------------------------------------------------------------------------#
#---------------------------------Statistiques descriptives------------------------------#
#----------------------------------------------------------------------------------------#
#chargement de la base de donn�es, la base contient 93832 obs. et 7 variables.
base<-read.csv("data/base.csv", header=TRUE, sep=";", dec=",")
#on enl�ve la variable Xi
base<-select(base, -X)
base$date=ymd(base$date)
#chargement de la base de donn�es piezo
piezo<-read.csv2("data/PiezoLaFerriereHarang.csv", header=TRUE, dec=",", sep=";")
piezo$date=ymd(piezo$date)#on met au format date

base825<-filter(base, id_sonde==825) #base825 contient les observations de la sonde 825
base827<-filter(base, id_sonde==827) #base827 contient les observations de la sonde 827
base828<-filter(base, id_sonde==828) #base828 contient les observations de la sonde 828
base830<-filter(base, id_sonde==830) #base830 contient les observations de la sonde 830

#calcul du coefficient de corr�lation entre la Teau et Tair relev�es par toutes les sondes. 
cor.test(base$Teau, base$Tair.EOBS)
#repr�sentation graphique de la Teau et Tair relev�es par toutes les sondes
plot(Teau~date, data=base825 ,type="l", col="red", main="Temp�ratures de l'air et de l'eau dans la Touques", ylab = "Temp�ratures en C", ylim=c(-5,30))
lines(Teau~date, type="l", col="red", data=base827)
lines(Teau~date, type="l", col="red", data=base828)
lines(Teau~date, type="l", col="red", data=base830)
lines(Tair.EOBS~date, type="l", col="blue", data=base825)
lines(Tair.EOBS~date, type="l", col="blue", data=base827)
lines(Tair.EOBS~date, type="l", col="blue", data=base828)
lines(Tair.EOBS~date, type="l", col="blue", data=base830)
legend("topleft", legend=c("Teau", "Tair"),
       col=c("red", "blue"), lty=1, cex=0.8)

#r�sum� des informations de toutes les zones et comparaison des r�sultats
#les moyennes croissent en s'approchant de la mer
summary(base825$Teau)
summary(base827$Teau)
summary(base828$Teau)
summary(base830$Teau)

#repr�sentation graphique des r�sum�s des informations de toutes les zones
base$id_sonde<-as.factor(base$id_sonde) #pour l'utiliser, il est n�cessaire de convertir id_sonde en factor
p <- ggplot(base, aes(x=id_sonde, y=Teau)) + 
  geom_boxplot()
p
p <- ggplot(base, aes(x=id_sonde, y=Teau)) + 
  geom_violin()
p

#calcul des �cart-types de la Teau relev�e par chaque sonde
sd(base825$Teau)
sd(base827$Teau)
sd(base828$Teau)
sd(base830$Teau)

#calcul des �tendus de la Teau relev�e par chaque sonde
#il y a moins d'�tendu de la Teau en s'�loignant de la mer
#e.g. la max(Teau) se r�duit en s'�loignant de la mer
max(base825$Teau) - min(base825$Teau)
max(base827$Teau) - min(base827$Teau)
max(base828$Teau) - min(base828$Teau)
max(base830$Teau) - min(base830$Teau)

#repr�sentation graphique du nuage de points de Teau et Tair
#m�me quand la -5<=Tair<=0, Teau>0
plot(Teau~Tair.EOBS, data=base825, type="p", col="red", ylim=c(-5,30))


#----------------------------------------------------------------------------------------#
#-------------------------Pr�paration des donn�es pour l'ACI-----------------------------#
#----------------------------------------------------------------------------------------#
BASE1<-aggregate(Teau~date+id_sonde, data=base825,FUN=mean, na.rm=TRUE)#r�cup�rer la variable Teau observ� par la sonde 825 et la classer par date
BASE2<-aggregate(Tair.EOBS~date+id_sonde, data=base825,FUN=mean, na.rm=TRUE)#r�cup�rer la variable Tair.EOBS observ� par la sonde 825 et la classer par date
BASE<-merge(BASE1,BASE2, by=c("date", "id_sonde"))#merger les deux tables class�es par date et id_sonde
base_diff_825<-mutate(BASE, diff825=Teau-Tair.EOBS)

#on r�p�te le m�me processus pour les sondes : 827, 828, 830
BASE1b<-aggregate(Teau~date+id_sonde, data=base827,FUN=mean, na.rm=TRUE)
BASE2b<-aggregate(Tair.EOBS~date+id_sonde, data=base827,FUN=mean, na.rm=TRUE)
BASEb<-merge(BASE1b,BASE2b, by=c("date", "id_sonde"))
base_diff_827<-mutate(BASEb, diff827=Teau-Tair.EOBS)

BASE1b<-aggregate(Teau~date+id_sonde, data=base828,FUN=mean, na.rm=TRUE)
BASE2b<-aggregate(Tair.EOBS~date+id_sonde, data=base828,FUN=mean, na.rm=TRUE)
BASEb<-merge(BASE1b,BASE2b, by=c("date", "id_sonde"))
base_diff_828<-mutate(BASEb, diff828=Teau-Tair.EOBS)

BASE1b<-aggregate(Teau~date+id_sonde, data=base830,FUN=mean, na.rm=TRUE)
BASE2b<-aggregate(Tair.EOBS~date+id_sonde, data=base830,FUN=mean, na.rm=TRUE)
BASEb<-merge(BASE1b,BASE2b, by=c("date", "id_sonde"))
base_diff_830<-mutate(BASEb, diff830=Teau-Tair.EOBS)

base4<-merge(base_diff_825, base_diff_827, by="date")
base5<-merge(base4, base_diff_828, by="date")
base6<-merge(base5,base_diff_830, by="date")
base_diff<-select(base6, date, diff825, diff827,diff828, diff830)#construction d'une base des diff�rences (Teau - Tair) observ�es par toutes les sondes
summary(base_diff)

#repr�sentation graphique de la diff�rence Teau - Tair
plot(diff825~date, data=base_diff ,type="l", col="red", main="Diff�rence temp�rature de l'eau et de l'air captur�es par toutes les sondes", ylab = "Temp�ratures en C" , ylim=c(-10,20))
lines(diff827~date, type="l", col="red", data=base_diff)
lines(diff828~date, type="l", col="red", data=base_diff)
lines(diff830~date, type="l", col="red", data=base_diff)

base_diff_num<-select(base_diff, -date)#construction d'une base num�rique pour l'ACI
base_diff_dates<-select(base_diff, date)#construction d'une base de dates d'observations 

base_mean_teau_825<-aggregate(Teau~date,data=base825, FUN = mean, na.rm=T)#construction d'une base de moyennes journali�res de la Teau relev�e par la sonde 825
base_mean_teau_825$Teau825=base_mean_teau_825$Teau#renommer la variable Teau par Teau825
base_mean_teau_825<-select(base_mean_teau_825, -Teau)

#on r�p�te le m�me processus pour les sondes 827,828 et 830.
base_mean_teau_827<-aggregate(Teau~date,data=base827, FUN = mean, na.rm=T)
base_mean_teau_827$Teau827=base_mean_teau_827$Teau
base_mean_teau_827<-select(base_mean_teau_827, -Teau)

base_mean_teau_828<-aggregate(Teau~date,data=base828, FUN = mean, na.rm=T)
base_mean_teau_828$Teau828=base_mean_teau_828$Teau
base_mean_teau_828<-select(base_mean_teau_828, -Teau)

base_mean_teau_830<-aggregate(Teau~date,data=base830, FUN = mean, na.rm=T)
base_mean_teau_830$Teau830=base_mean_teau_830$Teau
base_mean_teau_830<-select(base_mean_teau_830, -Teau)

#repr�sentation des 4 courbes
#plot(Teau825~date, type="l", main="Evolution des temp�ratures de l'Odon", data=base_mean_teau_825, col="blue", ylab="temp�rature")
#lines (Teau827~date, type="l", data=base_mean_teau_827, col="black")
#lines (Teau828~date, type="l", data=base_mean_teau_828, col="red")
#lines (Teau830~date, type="l", data=base_mean_teau_830, col="yellow")
#legend("topleft", legend=c("825", "827", "828", "830"),
#       col=c("blue", "black", "red", "yellow"), lty=1, cex=0.8)

base4<-merge(base_mean_teau_825,base_mean_teau_827, by="date") 
base5<-merge(base4, base_mean_teau_828, by="date")
base6<-merge(base5, base_mean_teau_830, by="date")
base_mean_teau<-select(base6, date,Teau825, Teau827, Teau828, Teau830)

base_mean_teau_num<-select(base_mean_teau, -date)#construction d'une base num�rique pour l'ACI
#la base de dates d'observations est la m�me que "base_diff_dates"

#----------------------------------------------------------------------------------------#
#----------------------------------------ACI---------------------------------------------#
#----------------------------------------------------------------------------------------#
#S�paration par ACI des 3 composantes principales de la moyenne de la Teau de la Touques.
set.seed(1)# on met 1 pour initier le processus
a <- fastICA(base_mean_teau_num, 3, alg.typ = "parallel", fun = "logcosh", alpha = 1,
             method = "R", row.norm = FALSE, maxit = 200,
             tol = 0.0001, verbose = TRUE)

a$A
a$S #permet d'avoir les sources
A<-data.frame(a$S) #Cr�ation d'une dataframe
B<-cbind(base_diff_dates, A)

B$comp1=a$A[1,1]*a$S[,1]
B$comp2=a$A[2,1]*a$S[,2]
B$comp3=a$A[3,1]*a$S[,3]

plot(comp1~date, type="l", data=B, col="blue", ylim=c(-7, 7)) 
lines(comp2~date, type="l", data=B, col="red")
lines(comp3~date, type="l", data=B, col="black")
legend("topleft", legend=c("C1", "C2", "C3"),
        col=c("blue", "red", "black"), lty=1, cex=0.8)

#S�paration par ACI des 2 composantes principales de la diff�rence entre la Teau et Tair de la Touques.
set.seed(360)#la racine
a <- fastICA(base_diff_num, 2, alg.typ = "parallel", fun = "logcosh", alpha = 1,
             method = "R", row.norm = FALSE, 
             tol = 0.0001, verbose = TRUE)

a$A#la matrice de passage
A<-data.frame(a$S) #Cr�ation d'une dataframe
B<-cbind(base_diff_dates, A) #cr�ation d'une matrice B avec les dates

#repr�sentation des signaux 
par(mfrow = c(1,1))
plot(X1~date, type="l", col="red", data=B, main="composantes", ylim=c(-5,5))
lines(X2~date, type="l", col="blue", data=B)
legend("topleft", legend=c("C1", "C2"),
       col=c("blue", "red"), lty=1, cex=0.8)

#----------------------------------------------------------------------------------------#
#------------------------------D�composition de la s�rie 825-----------------------------#
#----------------------------------------------------------------------------------------#

par(mfrow = c(1,1))
B$comp1=a$A[1,1]*a$S[,1]#bien noter les coefs des matrices
B$comp2=a$A[2,1]*a$S[,2]

#repr�sentation des signaux
plot(comp2~date, type="l", data=B, col="red", ylim=c(-15,15))
#noter que la composante C2 ne varie pas trop
lines(comp1~date, type="l", data=B, col="blue")
legend("topleft", legend=c("C1", "C2"),
       col=c("blue", "red"), lty=1, cex=0.8)

#----------------------------------------------------------------------------------------#
#-------------------------Pr�paration des donn�es pour l'ACP-----------------------------#
#----------------------------------------------------------------------------------------#
#On va essayer d'expliquer nos composantes trouv�es avec ACI en int�grant dans l'ACP-----# 
#la variable m�t�orologique "Pluie" ainsi que la "piezom�trie"---------------------------#
#Lanalyse n'est men�e que pour la station 825--------------------------------------------#

base5<-select(base_diff_825, Teau, diff825, Tair.EOBS)
base7<-cbind(B, base5)
PE<-aggregate(Rainf.EOBS~date, data=base825, FUN=sum, na.rm=TRUE)#moyenne journali�re de la pluie
base_825_acp<-merge(base7, PE, by="date")#ajouter la pluie au jeu de donn�es pour l'ACP
base_825_acp<-merge(base_825_acp, piezo, by="date")#ajouter la variable piezo
base_825_acp<-select(base_825_acp, -date)#�tablissement de la matrice num�rique pour l'ACP
base_825_acp<-mutate(base_825_acp, C1=comp1, C2=comp2, Ta=Tair.EOBS, Tw=Teau, D=diff825, PE=Rainf.EOBS)
base_825_acp<-select(base_825_acp, C1, C2, Tw, Ta, D, PE, P)

#----------------------------------------------------------------------------------------#
#---------------------------------------ACP----------------------------------------------#
#----------------------------------------------------------------------------------------#

#res.pca=PCA(base_825_acp, graph = TRUE)
res.pca=PCA(base_825_acp, quanti.sup=6:7, graph = TRUE)#quanti.sup pour rajouter des variables illustratives
fviz_pca_var(res.pca, col.var = "cos2",
             gradient.cols = c("#00AFBB", "#E7B800", "#FC4E07"),
             repel = TRUE # �vite le chevauchement de texte
             )
#calcul des coefficients de corr�lation
cor(base_825_acp$Tw, base_825_acp$Ta)#forte corr�lation
cor(base_825_acp$C1, base_825_acp$C2)#corr�lation nulle car composantes ind�pendantes de l'ACI
cor(base_825_acp$C2, base_825_acp$Ta)#C2 et Ta ne sont pas li�es
cor(base_825_acp$C2, base_825_acp$P)#C2 et la pi�zom�trie ne sont pas li�es.
cor(base_825_acp$C1, base_825_acp$D)#fortement corr�l�es 

#valeurs propres
res.pca$eig
#repr�sentation graphique des valeurs propres
fviz_eig(res.pca, addlabels = TRUE, ylim = c(0, 80))
#on voit ici qu'il n'est pas n�cessaire de s'int�resser aux dimensions sup�rieures � 2, 
#elles contribuent peu � l'inertie totale
#r�sultats des variables
res.var <- res.pca$var
res.var$coord          # Coordonn�es
res.var$contrib        # Contributions aux axes
res.var$cos2           # Qualit� de repr�sentation
#----------------------------------------------------------------------------------------#
#----------------------------------------------------------------------------------------#