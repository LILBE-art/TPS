# ===============================
# Structures de base
# ===============================

import itertools

# Exemple
myrelations = [
    {'A', 'B', 'C', 'G', 'H', 'I'},
    {'X', 'Y'}
]

mydependencies = [
    ({'A'}, {'B'}),
    ({'A'}, {'C'}),
    ({'C', 'G'}, {'H'}),
    ({'C', 'G'}, {'I'}),
    ({'B'}, {'H'})
]

# ===============================
# 1. Affichage des dépendances
# ===============================

def printDependencies(F):
    for alpha, beta in F:
        print("\t", alpha, "-->", beta)

# ===============================
# 2. Affichage des relations
# ===============================

def printRelations(T):
    for R in T:
        print("\t", R)

# ===============================
# 3. Power set
# ===============================

def powerSet(inputset):
    result = []
    for r in range(1, len(inputset) + 1):
        result += list(map(set, itertools.combinations(inputset, r)))
    return result

# ===============================
# 4. Fermeture d’un ensemble K
# ===============================

def closure(F, K):
    closure_set = set(K)
    changed = True
    
    while changed:
        changed = False
        for alpha, beta in F:
            if alpha.issubset(closure_set):
                if not beta.issubset(closure_set):
                    closure_set |= beta
                    changed = True
    return closure_set

# ===============================
# 5. Fermeture de F
# ===============================

def closureF(F, R):
    result = []
    for subset in powerSet(R):
        result.append((subset, closure(F, subset)))
    return result

# ===============================
# 6. Vérifier α → β
# ===============================

def implies(F, alpha, beta):
    return beta.issubset(closure(F, alpha))

# ===============================
# 7. Vérifier super-clé
# ===============================

def isSuperKey(F, R, K):
    return closure(F, K) == R

# ===============================
# 8. Vérifier clé candidate
# ===============================

def isCandidateKey(F, R, K):
    if not isSuperKey(F, R, K):
        return False
    
    for attr in K:
        if isSuperKey(F, R, K - {attr}):
            return False
    
    return True

# ===============================
# 9. Toutes les clés candidates
# ===============================

def candidateKeys(F, R):
    keys = []
    for subset in powerSet(R):
        if isCandidateKey(F, R, subset):
            keys.append(subset)
    return keys

# ===============================
# 10. Toutes les super-clés
# ===============================

def superKeys(F, R):
    keys = []
    for subset in powerSet(R):
        if isSuperKey(F, R, subset):
            keys.append(subset)
    return keys

# ===============================
# 11. Trouver une clé candidate
# ===============================

def findCandidateKey(F, R):
    for subset in powerSet(R):
        if isCandidateKey(F, R, subset):
            return subset
    return None

# ===============================
# 12. Vérifier BCNF
# ===============================

def isBCNF(F, R):
    for alpha, beta in F:
        if not isSuperKey(F, R, alpha):
            return False
    return True

# ===============================
# 13. Vérifier BCNF pour schéma
# ===============================

def schemaBCNF(T, F):
    for R in T:
        if not isBCNF(F, R):
            return False
    return True

# ===============================
# 14. Décomposition BCNF
# ===============================

def decomposeBCNF(R, F):
    for alpha, beta in F:
        if not isSuperKey(F, R, alpha):
            R1 = alpha.union(beta)
            R2 = R - (beta - alpha)
            return [R1, R2]
    return [R]

# ===============================
# TEST RAPIDE
# ===============================

if __name__ == "__main__":
    R = {'A', 'B', 'C', 'G', 'H', 'I'}
    F = mydependencies

    print("Dépendances :")
    printDependencies(F)

    print("\nRelations :")
    printRelations(myrelations)

    print("\nFermeture de {A} :", closure(F, {'A'}))

    print("\nClés candidates :", candidateKeys(F, R))

    print("\nSuper-clés :", superKeys(F, R))

    print("\nEst BCNF :", isBCNF(F, R))