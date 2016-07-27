module Generic.Prelude where

open import Generic.Lib.Propositional public
open import Generic.Lib.Heteroindexed public
open import Generic.Lib.Decidable public
open import Generic.Lib.Category public
open import Generic.Lib.Reflection public

open import Level renaming (zero to lzero; suc to lsuc) public
open import Function public
open import Data.Bool.Base hiding (_≟_) public
open import Data.Nat.Base as Nat hiding (_≟_; _⊔_; fold) public
open import Data.String.Base renaming (toList to toListˢ; _++_ to _++ˢ_) public
open import Data.Sum renaming (map to smap) public
open import Data.Product renaming (map to pmap; zip to pzip) hiding (_,′_) public
open import Data.List.Base public

open import Data.Maybe.Base using (Maybe; just; nothing)

infix  3 _∈_
infixl 2 _>>>_

data ⊥ {α} : Set α where
record ⊤ {α} : Set α where
  constructor tt

⊥₀ = ⊥ {lzero}
⊤₀ = ⊤ {lzero}

tt₀ : ⊤₀
tt₀ = tt

_>>>_ : ∀ {α β γ} {A : Set α} {B : A -> Set β} {C : ∀ {x} -> B x -> Set γ}
      -> (f : ∀ x -> B x) -> (∀ {x} -> (y : B x) -> C y) -> ∀ x -> C (f x)
(f >>> g) x = g (f x)

first : ∀ {α β γ} {A : Set α} {B : Set β} {C : A -> Set γ}
      -> (∀ x -> C x) -> (p : A × B) -> C (proj₁ p) × B
first f (x , y) = f x , y

second : ∀ {α β γ} {A : Set α} {B : A -> Set β} {C : A -> Set γ}
       -> (∀ {x} -> B x -> C x) -> Σ A B -> Σ A C
second g (x , y) = x , g y

Any : ∀ {α β} {A : Set α} -> (A -> Set β) -> List A -> Set β
Any B  []      = ⊥
Any B (x ∷ []) = B x
Any B (x ∷ xs) = B x ⊎ Any B xs

_∈_ : ∀ {α} {A : Set α} -> A -> List A -> Set
x ∈ xs = Any (x ≡_) xs

here : ∀ {α β} {A : Set α} {B : A -> Set β} {x} xs -> B x -> Any B (x ∷ xs)
here  []      y = y
here (x ∷ xs) y = inj₁ y

phere : ∀ {α} {A : Set α} {x : A} xs -> x ∈ x ∷ xs
phere xs = here xs refl

there : ∀ {α β} {A : Set α} {B : A -> Set β} {x} xs -> Any B xs -> Any B (x ∷ xs)
there  []      ()
there (x ∷ xs) a  = inj₂ a

mapAny : ∀ {α β γ} {A : Set α} {B : A -> Set β} {C : A -> Set γ}
       -> ∀ xs -> (∀ {x} -> B x -> C x) -> Any B xs -> Any C xs
mapAny  []           g  ()
mapAny (x ∷ [])      g  y       = g y
mapAny (x ∷ x′ ∷ xs) g (inj₁ y) = inj₁ (g y)
mapAny (x ∷ x′ ∷ xs) g (inj₂ r) = inj₂ (mapAny (x′ ∷ xs) g r)

All : ∀ {α β} {A : Set α} -> (A -> Set β) -> List A -> Set β
All B  []      = ⊤
All B (x ∷ xs) = B x × All B xs

allToList : ∀ {α β} {A : Set α} {B : Set β} {xs : List A} -> All (const B) xs -> List B
allToList {xs = []}      tt      = []
allToList {xs = x ∷ xs} (y , ys) = y ∷ allToList ys

lookupAllConst : ∀ {α β} {A : Set α} {B : Set β} {{bEq : Eq B}} {xs : List A}
               -> B -> All (const B) xs -> Maybe (∃ (_∈ xs))
lookupAllConst {xs = []}     y  tt      = nothing
lookupAllConst {xs = x ∷ xs} y (z , ys) = if y == z
  then just (, phere xs)
  else second (there xs) <$> lookupAllConst y ys

,-inj : ∀ {α β} {A : Set α} {B : A -> Set β} {x₁ x₂} {y₁ : B x₁} {y₂ : B x₂}
      -> (x₁ , y₁) ≡ (x₂ , y₂) -> [ B ] y₁ ≅ y₂
,-inj refl = irefl

inj₁-inj : ∀ {α β} {A : Set α} {B : Set β} {x₁ x₂ : A}
         -> inj₁ {B = B} x₁ ≡ inj₁ x₂ -> x₁ ≡ x₂
inj₁-inj refl = refl

inj₂-inj : ∀ {α β} {A : Set α} {B : Set β} {y₁ y₂ : B}
         -> inj₂ {A = A} y₁ ≡ inj₂ y₂ -> y₁ ≡ y₂
inj₂-inj refl = refl

_<,>ᵈ_ : ∀ {α β} {A : Set α} {B : Set β} {x₁ x₂ : A} {y₁ y₂ : B}
       -> x₁ # x₂ -> y₁ # y₂ -> x₁ , y₁ # x₂ , y₂
_<,>ᵈ_ = dcong₂ _,_ (inds-homo ∘ ,-inj)

_<,>ᵈᵒ_ : ∀ {α β} {A : Set α} {B : A -> Set β} {x₁ x₂} {y₁ : B x₁} {y₂ : B x₂}
        -> x₁ # x₂ -> (∀ y₂ -> y₁ # y₂) -> x₁ , y₁ # x₂ , y₂
_<,>ᵈᵒ_ = dhcong₂ _,_ ,-inj

decSum : ∀ {α β} {A : Set α} {B : Set β} -> IsSet A -> IsSet B -> IsSet (A ⊎ B)
decSum f g (inj₁ x₁) (inj₁ x₂) = dcong inj₁ inj₁-inj (f x₁ x₂)
decSum f g (inj₂ y₁) (inj₂ y₂) = dcong inj₂ inj₂-inj (g y₁ y₂)
decSum f g (inj₁ x₁) (inj₂ y₂) = no λ()
decSum f g (inj₂ y₁) (inj₁ x₂) = no λ()

instance
  ,-inst : ∀ {α β} {A : Set α} {B : A -> Set β} {{x : A}} {{y : B x}} -> Σ A B
  ,-inst {{x}} {{y}} = x , y

  ℕEq : Eq ℕ
  ℕEq = viaBase Nat._≟_
