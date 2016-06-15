module Generic.Core where

open import Generic.Prelude public

Pi : ∀ {α β} -> Bool -> (A : Set α) -> (A -> Set β) -> Set (α ⊔ β)
Pi true  A B = (x : A) -> B x
Pi false A B = {x : A} -> B x

apply : ∀ {α β} {A : Set α} {B : A -> Set β} b -> Pi b A B -> ∀ x -> B x
apply true  f x = f x
apply false y x = y

Coerce′ : ∀ {α β} -> α ≡ β -> Set α -> Set β
Coerce′ refl = id

Coerce : ∀ {α β} -> α ≡ β -> Set α -> Set β
Coerce q A = Apply (λ q -> Coerce′ q A) q

coerce′ : ∀ {α β} {A : Set α} -> (q : α ≡ β) -> A -> Coerce′ q A
coerce′ refl = id

coerce : ∀ {α β} {A : Set α} {q : α ≡ β} -> A -> Coerce q A
coerce {q = refl} = tag

uncoerce′ : ∀ {α β} {A : Set α} -> (q : α ≡ β) -> Coerce′ q A -> A
uncoerce′ refl = id

unproj₁′ : ∀ {α β γ} {A : Set α} {B : A -> Set β}
         -> (q : α ⊔ β ≡ γ) -> Coerce′ q (Σ A B) -> A
unproj₁′ = proj₁ % ∘ uncoerce′

unproj₂′ : ∀ {α β γ} {A : Set α} {B : A -> Set β}
         -> (q : α ⊔ β ≡ γ) -> (p : Coerce′ q (Σ A B)) -> B (unproj₁′ q p)
unproj₂′ = proj₂ % ∘ uncoerce′

uncoerce : ∀ {α β} {A : Set α} {q : α ≡ β} -> Coerce q A -> A
uncoerce {q = q} x = uncoerce′ q (detag x)

unproj₁ : ∀ {α β γ} {A : Set α} {B : A -> Set β} {q : α ⊔ β ≡ γ}
        -> Coerce q (Σ A B) -> A
unproj₁ = proj₁ ∘ uncoerce

unproj₂ : ∀ {α β γ} {A : Set α} {B : A -> Set β} {q : α ⊔ β ≡ γ}
        -> (p : Coerce q (Σ A B)) -> B (unproj₁ p)
unproj₂ = proj₂ ∘ uncoerce

split′ : ∀ {α β γ δ} {A : Set α} {B : A -> Set β} {C : Set γ}
       -> (q : α ⊔ β ≡ δ) -> Coerce′ q (Σ A B) -> (∀ x -> B x -> C) -> C
split′ q p g = uncurry g (uncoerce′ q p)

split : ∀ {α β γ δ} {A : Set α} {B : A -> Set β} {C : Set γ} {q : α ⊔ β ≡ δ}
      -> Coerce q (Σ A B) -> (∀ x -> B x -> C) -> C
split {q = q} p = split′ q (detag p)

-- split : ∀ {α β γ δ} {A : Set α} {B : A -> Set β} {C : Set γ} {q : α ⊔ β ≡ δ}
--       -> Coerce q (Σ A B) -> (∀ x -> B x -> C) -> C
-- split p g = uncurry g (uncoerce p)

-- split′ : ∀ {α β γ δ} {A : Set α} {B : A -> Set β} {C : Set γ}
--        -> (q : α ⊔ β ≡ δ) -> Coerce′ q (Σ A B) -> (∀ x -> B x -> C) -> C
-- split′ q p = split (tagWith q p)

transform : ∀ {α β γ δ ε} {A : Set α} {B : A -> Set β} {q₁ : α ⊔ β ≡ γ} {{q₂ : δ ≡ ε}}
          -> Coerce q₁ (Σ A B) -> (∀ x -> B x -> Set δ) -> Set ε
transform {{q₂}} p C = split p λ x y -> Coerce′ q₂ (C x y)

splitWith₂ : ∀ {α β γ δ} {A : Set α} {B : A -> Set β}
           -> (q : α ⊔ β ≡ δ)
           -> (C : ∀ {δ} {r : α ⊔ β ≡ δ} -> Coerce′ r (Σ A B) -> Coerce′ r (Σ A B) -> Set γ)
           -> (p₁ p₂ : Coerce′ q (Σ A B))
           -> (∀ x₁ x₂ y₁ y₂ -> C {r = refl} (x₁ , y₁) (x₂ , y₂))
           -> C {r = q} p₁ p₂
splitWith₂ refl C (x₁ , y₁) (x₂ , y₂) g = g x₁ x₂ y₁ y₂

data Shape : Set where
  varˢ : Shape
  πˢ   : Shape -> Shape
  _⊛ˢ_ : Shape -> Shape -> Shape 

module _ {ι} (I : Set ι) β where
  data Desc : Shape -> Set (ι ⊔ lsuc β) where
    var : I -> Desc varˢ
    π   : ∀ {α s} {{q : α ⊔ β ≡ β}}
        -> Bool
        -> Coerce (cong (λ αβ -> ι ⊔ lsuc αβ) q) (∃ λ (A : Set α) -> A -> Desc s)
        -> Desc (πˢ s)
    _⊛_ : ∀ {s t} -> Desc s -> Desc t -> Desc (s ⊛ˢ t)

pattern pi  A D = π true  (tag (A , D))
pattern ipi A D = π false (tag (A , D))

⟦_⟧ : ∀ {ι β s} {I : Set ι} -> Desc I β s -> (I -> Set β) -> Set β
⟦ var i ⟧ B = B i
⟦ π b P ⟧ B = transform P λ A D -> Pi b A λ x -> ⟦ D x ⟧ B
⟦ D ⊛ E ⟧ B = ⟦ D ⟧ B × ⟦ E ⟧ B

Extend : ∀ {ι β s} {I : Set ι} -> Desc I β s -> (I -> Set β) -> I -> Set β
Extend (var i) B j = Lift (i ≡ j)
Extend (π b P) B j = transform P λ A D -> ∃ λ x -> Extend (D x) B j
Extend (D ⊛ E) B j = ⟦ D ⟧ B × Extend E B j

Data : ∀ {ι} -> Set ι -> ∀ β -> Set (ι ⊔ lsuc β)
Data I β = IList (Desc I β)

-- record μ {ι β} {I : Set ι} (Ds : Data I β) j : Set β where
--   inductive
--   constructor node
--   field knot : Any (λ D -> Extend D (μ Ds) j) Ds

data μ {ι β} {I : Set ι} (Ds : Data I β) j : Set β where
  node : Any (λ D -> Extend D (μ Ds) j) Ds -> μ Ds j

node-inj : ∀ {i β} {I : Set i} {Ds : Data I β} {j} {e₁ e₂ : Any (λ D -> Extend D (μ Ds) j) Ds}
         -> node {Ds = Ds} e₁ ≡ node e₂ -> e₁ ≡ e₂
node-inj refl = refl
